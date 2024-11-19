# frozen_string_literal: true

module Gitlab
  module Git
    class Diff
      TimeoutError = Class.new(StandardError)
      include Gitlab::EncodingHelper

      # Diff properties
      attr_accessor :old_path, :new_path, :a_mode, :b_mode, :diff

      # Stats properties
      attr_accessor :new_file, :renamed_file, :deleted_file, :generated, :encoded_file_path

      alias_method :new_file?, :new_file
      alias_method :deleted_file?, :deleted_file
      alias_method :renamed_file?, :renamed_file

      attr_accessor :expanded
      attr_writer :too_large

      alias_method :expanded?, :expanded
      alias_method :generated?, :generated

      # The default maximum content size to display a diff patch.
      #
      # If this value ever changes, make sure to create a migration to update
      # current records, and default of `ApplicationSettings#diff_max_patch_bytes`.
      DEFAULT_MAX_PATCH_BYTES = 200.kilobytes

      # This is a limitation applied on the source (Gitaly), therefore we don't allow
      # persisting limits over that.
      MAX_PATCH_BYTES_UPPER_BOUND = 500.kilobytes

      SERIALIZE_KEYS = %i[
        diff
        new_path
        old_path
        a_mode
        b_mode
        new_file
        renamed_file
        deleted_file
        too_large
        generated
        encoded_file_path
      ].freeze

      BINARY_NOTICE_PATTERN = %r{Binary files (.*) and (.*) differ}

      class << self
        def between(repo, head, base, options = {}, *paths)
          straight = options.delete(:straight) || false

          common_commit = if straight
                            base
                          else
                            # Only show what is new in the source branch
                            # compared to the target branch, not the other way
                            # around. The line below with merge_base is
                            # equivalent to diff with three dots (git diff
                            # branch1...branch2) From the git documentation:
                            # "git diff A...B" is equivalent to "git diff
                            # $(git-merge-base A B) B"
                            repo.merge_base(head, base)
                          end

          options ||= {}
          actual_options = filter_diff_options(options)
          repo.diff(common_commit, head, actual_options, *paths)
        end

        # Return a copy of the +options+ hash containing only recognized keys.
        # Allowed options are:
        #
        #  :ignore_whitespace_change ::
        #    If true, changes in amount of whitespace will be ignored.
        #
        #  :max_files ::
        #    Limit how many files will patches be allowed for before collapsing
        #
        #  :max_lines ::
        #    Limit how many patch lines (across all files) will be allowed for
        #    before collapsing
        #
        #  :limits ::
        #    A hash with additional limits to check before collapsing patches.
        #    Allowed keys are: `max_bytes`, `safe_max_files`, `safe_max_lines`
        #    and `safe_max_bytes`
        #
        #  :expanded ::
        #    If false, patch raw data will not be included in the diff after
        #    `max_files`, `max_lines` or any of the limits in `limits` are
        #    exceeded
        #  :generated_files ::
        #    If the list of generated files is given, those files will be marked
        #    as generated.
        def filter_diff_options(options, default_options = {})
          allowed_options = [:ignore_whitespace_change, :max_files, :max_lines,
                             :limits, :expanded, :collect_all_paths, :generated_files, :offset_index]

          if default_options
            actual_defaults = default_options.dup
            actual_defaults.keep_if do |key|
              allowed_options.include?(key)
            end
          else
            actual_defaults = {}
          end

          if options
            filtered_opts = options.dup
            filtered_opts.keep_if do |key|
              allowed_options.include?(key)
            end
            filtered_opts = actual_defaults.merge(filtered_opts)
          else
            filtered_opts = actual_defaults
          end

          filtered_opts
        end

        # Return a binary diff message like:
        #
        # "Binary files a/file/path and b/file/path differ\n"
        # This is used when we detect that a diff is binary
        # using CharlockHolmes.
        def binary_message(old_path, new_path)
          "Binary files #{old_path} and #{new_path} differ\n"
        end

        # Returns the limit of bytes a single diff file can reach before it
        # appears as 'collapsed' for end-users.
        # By convention, it's 10% of the persisted `diff_max_patch_bytes`.
        #
        # Example: If we have 100k for the `diff_max_patch_bytes`, it will be 10k by
        # default.
        #
        # Patches surpassing this limit should still be persisted in the database.
        def patch_safe_limit_bytes(limit = patch_hard_limit_bytes)
          limit / 10
        end

        def collect_patch_overage?
          !!Feature.enabled?(:collect_all_diff_paths)
        end

        # Returns the limit for a single diff file (patch).
        #
        # Patches surpassing this limit shouldn't be persisted in the database
        # and will be presented as 'too large' for end-users.
        def patch_hard_limit_bytes
          Gitlab::CurrentSettings.diff_max_patch_bytes
        end

        def has_binary_notice?(text)
          return false unless text.present?

          text.start_with?(BINARY_NOTICE_PATTERN)
        end
      end
      def initialize(raw_diff, expanded: true, replace_invalid_utf8_chars: true, generated: nil)
        @expanded = expanded
        @generated = generated

        case raw_diff
        when Hash
          init_from_hash(raw_diff)
          prune_diff_if_eligible
        when Gitlab::GitalyClient::Diff
          init_from_gitaly(raw_diff)
          prune_diff_if_eligible
        when Gitaly::CommitDelta
          init_from_gitaly(raw_diff)
        when nil
          raise "Nil as raw diff passed"
        else
          raise "Invalid raw diff type: #{raw_diff.class}"
        end

        encode_diff_to_utf8(replace_invalid_utf8_chars)
      end

      def to_hash
        hash = {}

        SERIALIZE_KEYS.each do |key|
          hash[key] = send(key) # rubocop:disable GitlabSecurity/PublicSend
        end

        hash
      end

      def mode_changed?
        a_mode && b_mode && a_mode != b_mode
      end

      def submodule?
        a_mode == '160000' || b_mode == '160000'
      end

      def unidiff
        return diff if diff.blank?
        return json_safe_diff if detect_binary?(@diff) || has_binary_notice?

        old_path_header = new_file? ? '/dev/null' : "a/#{old_path}"
        new_path_header = deleted_file? ? '/dev/null' : "b/#{new_path}"

        "--- #{old_path_header}\n+++ #{new_path_header}\n" + diff
      end

      def line_count
        @line_count ||= Util.count_lines(@diff)
      end

      def diff_bytesize
        @diff_bytesize ||= @diff.bytesize
      end

      def too_large?
        if @too_large.nil?
          @too_large = diff_bytesize >= self.class.patch_hard_limit_bytes
        else
          @too_large
        end
      end

      # This is used by `to_hash` and `init_from_hash`.
      alias_method :too_large, :too_large?

      def prune!
        @diff = ''
        @line_count = 0
      end

      def too_large!
        prune!
        @too_large = true
      end

      def collapsed?
        return @collapsed if defined?(@collapsed)

        @collapsed = !expanded && diff_bytesize >= self.class.patch_safe_limit_bytes
      end

      def collapse!
        prune!
        @collapsed = true
      end

      def overflow?
        return @overflow if defined?(@overflow)

        # If overflow is not defined, we're
        # not recieveing a diff from Gitaly
        # and overflow has no meaning
        false
      end

      def json_safe_diff
        return @diff unless detect_binary?(@diff)

        # the diff is binary, let's make a message for it
        Diff.binary_message(@old_path, @new_path)
      end

      def has_binary_notice?
        self.class.has_binary_notice?(@diff)
      end

      private

      def collapse_generated_file?
        generated? && !expanded
      end

      def encode_diff_to_utf8(replace_invalid_utf8_chars)
        return unless replace_invalid_utf8_chars && diff_should_be_converted?

        @diff = Gitlab::EncodingHelper.encode_utf8_with_replacement_character(@diff)
      end

      def diff_should_be_converted?
        !detect_binary?(@diff) || !@diff&.valid_encoding?
      end

      def init_from_hash(hash)
        raw_diff = hash.symbolize_keys

        SERIALIZE_KEYS.each do |key|
          send(:"#{key}=", raw_diff[key.to_sym]) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def init_from_gitaly(gitaly_diff)
        @diff = gitaly_diff.try(:patch).present? ? encode!(gitaly_diff.patch) : ''
        @new_path = encode!(gitaly_diff.to_path.dup)
        @old_path = encode!(gitaly_diff.from_path.dup)
        @a_mode = gitaly_diff.old_mode.to_s(8)
        @b_mode = gitaly_diff.new_mode.to_s(8)
        @new_file = Gitlab::Git.blank_ref?(gitaly_diff.from_id)
        @renamed_file = gitaly_diff.from_path != gitaly_diff.to_path
        @deleted_file = Gitlab::Git.blank_ref?(gitaly_diff.to_id)
        @too_large = gitaly_diff.too_large if gitaly_diff.respond_to?(:too_large)
        gitaly_overflow = gitaly_diff.try(:overflow_marker)
        @overflow = Diff.collect_patch_overage? && gitaly_overflow
        @encoded_file_path = file_path_encoded?(gitaly_diff.to_path, @new_path) ||
          file_path_encoded?(gitaly_diff.from_path, @old_path)

        collapse! if gitaly_diff.respond_to?(:collapsed) && gitaly_diff.collapsed
        # Diffs exceeding limits returned from gitaly when "collect_all_paths" are enabled
        # are already pruned, but should be "collapsed" as they have no content
        @collapsed = true if @overflow
      end

      def prune_diff_if_eligible
        # If we have overflow, diffs are already pruned, retain line counts
        return if overflow?

        if too_large?
          ::Gitlab::Metrics.add_event(:patch_hard_limit_bytes_hit)

          too_large!
        elsif collapsed? || collapse_generated_file?
          collapse!
        end
      end

      def file_path_encoded?(raw_path, encoded_path)
        return false unless raw_path && encoded_path

        # We need to compare paths in the same encoding as they won't be equal
        # and return false positive when compared using different encoding.
        #
        # If the `encoded_path` was cleaned up (invalid UTF-8 characters were
        # removed) during encoding, we can then consider that the file paths are
        # no longer equal.
        raw_path != encoded_path.dup.force_encoding(raw_path.encoding)
      end
    end
  end
end
