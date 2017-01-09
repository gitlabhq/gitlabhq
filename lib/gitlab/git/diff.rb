# Gitlab::Git::Diff is a wrapper around native Rugged::Diff object
module Gitlab
  module Git
    class Diff
      class TimeoutError < StandardError; end
      include Gitlab::Git::EncodingHelper

      # Diff properties
      attr_accessor :old_path, :new_path, :a_mode, :b_mode, :diff

      # Stats properties
      attr_accessor :new_file, :renamed_file, :deleted_file

      attr_accessor :too_large

      # The maximum size of a diff to display.
      DIFF_SIZE_LIMIT = 102400 # 100 KB

      # The maximum size before a diff is collapsed.
      DIFF_COLLAPSE_LIMIT = 10240 # 10 KB

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
                            repo.merge_base_commit(head, base)
                          end

          options ||= {}
          actual_options = filter_diff_options(options)
          repo.diff(common_commit, head, actual_options, *paths)
        end

        # Return a copy of the +options+ hash containing only keys that can be
        # passed to Rugged.  Allowed options are:
        #
        #  :max_size ::
        #    An integer specifying the maximum byte size of a file before a it
        #    will be treated as binary. The default value is 512MB.
        #
        #  :context_lines ::
        #    The number of unchanged lines that define the boundary of a hunk
        #    (and to display before and after the actual changes). The default is
        #    3.
        #
        #  :interhunk_lines ::
        #    The maximum number of unchanged lines between hunk boundaries before
        #    the hunks will be merged into a one. The default is 0.
        #
        #  :old_prefix ::
        #    The virtual "directory" to prefix to old filenames in hunk headers.
        #    The default is "a".
        #
        #  :new_prefix ::
        #    The virtual "directory" to prefix to new filenames in hunk headers.
        #    The default is "b".
        #
        #  :reverse ::
        #    If true, the sides of the diff will be reversed.
        #
        #  :force_text ::
        #    If true, all files will be treated as text, disabling binary
        #    attributes & detection.
        #
        #  :ignore_whitespace ::
        #    If true, all whitespace will be ignored.
        #
        #  :ignore_whitespace_change ::
        #    If true, changes in amount of whitespace will be ignored.
        #
        #  :ignore_whitespace_eol ::
        #    If true, whitespace at end of line will be ignored.
        #
        #  :ignore_submodules ::
        #    if true, submodules will be excluded from the diff completely.
        #
        #  :patience ::
        #    If true, the "patience diff" algorithm will be used (currenlty
        #    unimplemented).
        #
        #  :include_ignored ::
        #    If true, ignored files will be included in the diff.
        #
        #  :include_untracked ::
        #   If true, untracked files will be included in the diff.
        #
        #  :include_unmodified ::
        #    If true, unmodified files will be included in the diff.
        #
        #  :recurse_untracked_dirs ::
        #    Even if +:include_untracked+ is true, untracked directories will
        #    only be marked with a single entry in the diff. If this flag is set
        #    to true, all files under ignored directories will be included in the
        #    diff, too.
        #
        #  :disable_pathspec_match ::
        #    If true, the given +*paths+ will be applied as exact matches,
        #    instead of as fnmatch patterns.
        #
        #  :deltas_are_icase ::
        #    If true, filename comparisons will be made with case-insensitivity.
        #
        #  :include_untracked_content ::
        #    if true, untracked content will be contained in the the diff patch
        #    text.
        #
        #  :skip_binary_check ::
        #    If true, diff deltas will be generated without spending time on
        #    binary detection. This is useful to improve performance in cases
        #    where the actual file content difference is not needed.
        #
        #  :include_typechange ::
        #    If true, type changes for files will not be interpreted as deletion
        #    of the "old file" and addition of the "new file", but will generate
        #    typechange records.
        #
        #  :include_typechange_trees ::
        #    Even if +:include_typechange+ is true, blob -> tree changes will
        #    still usually be handled as a deletion of the blob. If this flag is
        #    set to true, blob -> tree changes will be marked as typechanges.
        #
        #  :ignore_filemode ::
        #    If true, file mode changes will be ignored.
        #
        #  :recurse_ignored_dirs ::
        #    Even if +:include_ignored+ is true, ignored directories will only be
        #    marked with a single entry in the diff. If this flag is set to true,
        #    all files under ignored directories will be included in the diff,
        #    too.
        def filter_diff_options(options, default_options = {})
          allowed_options = [:max_size, :context_lines, :interhunk_lines,
                             :old_prefix, :new_prefix, :reverse, :force_text,
                             :ignore_whitespace, :ignore_whitespace_change,
                             :ignore_whitespace_eol, :ignore_submodules,
                             :patience, :include_ignored, :include_untracked,
                             :include_unmodified, :recurse_untracked_dirs,
                             :disable_pathspec_match, :deltas_are_icase,
                             :include_untracked_content, :skip_binary_check,
                             :include_typechange, :include_typechange_trees,
                             :ignore_filemode, :recurse_ignored_dirs, :paths,
                             :max_files, :max_lines, :all_diffs, :no_collapse]

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
      end

      def initialize(raw_diff, collapse: false)
        case raw_diff
        when Hash
          init_from_hash(raw_diff, collapse: collapse)
        when Rugged::Patch, Rugged::Diff::Delta
          init_from_rugged(raw_diff, collapse: collapse)
        when nil
          raise "Nil as raw diff passed"
        else
          raise "Invalid raw diff type: #{raw_diff.class}"
        end
      end

      def serialize_keys
        @serialize_keys ||= %i(diff new_path old_path a_mode b_mode new_file renamed_file deleted_file too_large)
      end

      def to_hash
        hash = {}

        keys = serialize_keys

        keys.each do |key|
          hash[key] = send(key)
        end

        hash
      end

      def submodule?
        a_mode == '160000' || b_mode == '160000'
      end

      def line_count
        @line_count ||= Util.count_lines(@diff)
      end

      def too_large?
        if @too_large.nil?
          @too_large = @diff.bytesize >= DIFF_SIZE_LIMIT
        else
          @too_large
        end
      end

      def collapsible?
        @diff.bytesize >= DIFF_COLLAPSE_LIMIT
      end

      def prune_large_diff!
        @diff = ''
        @line_count = 0
        @too_large = true
      end

      def collapsed?
        return @collapsed if defined?(@collapsed)
        false
      end

      def prune_collapsed_diff!
        @diff = ''
        @line_count = 0
        @collapsed = true
      end

      private

      def init_from_rugged(rugged, collapse: false)
        if rugged.is_a?(Rugged::Patch)
          init_from_rugged_patch(rugged, collapse: collapse)
          d = rugged.delta
        else
          d = rugged
        end

        @new_path = encode!(d.new_file[:path])
        @old_path = encode!(d.old_file[:path])
        @a_mode = d.old_file[:mode].to_s(8)
        @b_mode = d.new_file[:mode].to_s(8)
        @new_file = d.added?
        @renamed_file = d.renamed?
        @deleted_file = d.deleted?
      end

      def init_from_rugged_patch(patch, collapse: false)
        # Don't bother initializing diffs that are too large. If a diff is
        # binary we're not going to display anything so we skip the size check.
        return if !patch.delta.binary? && prune_large_patch(patch, collapse)

        @diff = encode!(strip_diff_headers(patch.to_s))
      end

      def init_from_hash(hash, collapse: false)
        raw_diff = hash.symbolize_keys

        serialize_keys.each do |key|
          send(:"#{key}=", raw_diff[key.to_sym])
        end

        prune_large_diff! if too_large?
        prune_collapsed_diff! if collapse && collapsible?
      end

      # If the patch surpasses any of the diff limits it calls the appropiate
      # prune method and returns true. Otherwise returns false.
      def prune_large_patch(patch, collapse)
        size = 0

        patch.each_hunk do |hunk|
          hunk.each_line do |line|
            size += line.content.bytesize

            if size >= DIFF_SIZE_LIMIT
              prune_large_diff!
              return true
            end
          end
        end

        if collapse && size >= DIFF_COLLAPSE_LIMIT
          prune_collapsed_diff!
          return true
        end

        false
      end

      # Strip out the information at the beginning of the patch's text to match
      # Grit's output
      def strip_diff_headers(diff_text)
        # Delete everything up to the first line that starts with '---' or
        # 'Binary'
        diff_text.sub!(/\A.*?^(---|Binary)/m, '\1')

        if diff_text.start_with?('---', 'Binary')
          diff_text
        else
          # If the diff_text did not contain a line starting with '---' or
          # 'Binary', return the empty string. No idea why; we are just
          # preserving behavior from before the refactor.
          ''
        end
      end
    end
  end
end
