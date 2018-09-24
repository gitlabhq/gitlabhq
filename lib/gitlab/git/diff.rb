module Gitlab
  module Git
    class Diff
      TimeoutError = Class.new(StandardError)
      include Gitlab::EncodingHelper

      # Diff properties
      attr_accessor :old_path, :new_path, :a_mode, :b_mode, :diff

      # Stats properties
      attr_accessor :new_file, :renamed_file, :deleted_file

      alias_method :new_file?, :new_file
      alias_method :deleted_file?, :deleted_file
      alias_method :renamed_file?, :renamed_file

      attr_accessor :expanded
      attr_writer :too_large

      alias_method :expanded?, :expanded

      SERIALIZE_KEYS = %i(diff new_path old_path a_mode b_mode new_file renamed_file deleted_file too_large).freeze

      # The maximum size of a diff to display.
      SIZE_LIMIT = 100.kilobytes

      # The maximum size before a diff is collapsed.
      COLLAPSE_LIMIT = 10.kilobytes

      class << self
        def between(repo, head, base, options = {}, *paths)
          straight = options.delete(:straight) || false

          common_commit = if straight
                            base
                          else
                            # Only show what is new in the source branch
                            # compared to the target branch, not the other way
                            # around. The linex below with merge_base is
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
        #    If true, patch raw data will not be included in the diff after
        #    `max_files`, `max_lines` or any of the limits in `limits` are
        #    exceeded
        def filter_diff_options(options, default_options = {})
          allowed_options = [:ignore_whitespace_change, :max_files, :max_lines,
                             :limits, :expanded]

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
      end

      def initialize(raw_diff, expanded: true)
        @expanded = expanded

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

      def line_count
        @line_count ||= Util.count_lines(@diff)
      end

      def too_large?
        if @too_large.nil?
          @too_large = @diff.bytesize >= SIZE_LIMIT
        else
          @too_large
        end
      end

      # This is used by `to_hash` and `init_from_hash`.
      alias_method :too_large, :too_large?

      def too_large!
        @diff = ''
        @line_count = 0
        @too_large = true
      end

      def collapsed?
        return @collapsed if defined?(@collapsed)

        @collapsed = !expanded && @diff.bytesize >= COLLAPSE_LIMIT
      end

      def collapse!
        @diff = ''
        @line_count = 0
        @collapsed = true
      end

      def json_safe_diff
        return @diff unless detect_binary?(@diff)

        # the diff is binary, let's make a message for it
        Diff.binary_message(@old_path, @new_path)
      end

      def has_binary_notice?
        @diff.start_with?('Binary')
      end

      private

      def init_from_hash(hash)
        raw_diff = hash.symbolize_keys

        SERIALIZE_KEYS.each do |key|
          send(:"#{key}=", raw_diff[key.to_sym]) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def init_from_gitaly(diff)
        @diff = encode!(diff.patch) if diff.respond_to?(:patch)
        @new_path = encode!(diff.to_path.dup)
        @old_path = encode!(diff.from_path.dup)
        @a_mode = diff.old_mode.to_s(8)
        @b_mode = diff.new_mode.to_s(8)
        @new_file = diff.from_id == BLANK_SHA
        @renamed_file = diff.from_path != diff.to_path
        @deleted_file = diff.to_id == BLANK_SHA
        @too_large = diff.too_large if diff.respond_to?(:too_large)

        collapse! if diff.respond_to?(:collapsed) && diff.collapsed
      end

      def prune_diff_if_eligible
        if too_large?
          too_large!
        elsif collapsed?
          collapse!
        end
      end

      # If the patch surpasses any of the diff limits it calls the appropiate
      # prune method and returns true. Otherwise returns false.
      def prune_large_patch(patch)
        size = 0

        patch.each_hunk do |hunk|
          hunk.each_line do |line|
            size += line.content.bytesize

            if size >= SIZE_LIMIT
              too_large!
              return true # rubocop:disable Cop/AvoidReturnFromBlocks
            end
          end
        end

        if !expanded && size >= COLLAPSE_LIMIT
          collapse!
          return true
        end

        false
      end
    end
  end
end
