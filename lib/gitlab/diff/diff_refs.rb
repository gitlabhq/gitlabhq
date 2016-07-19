module Gitlab
  module Diff
    class DiffRefs
      attr_reader :base_sha
      attr_reader :start_sha
      attr_reader :head_sha

      def initialize(base_sha:, start_sha: base_sha, head_sha:)
        @base_sha = base_sha
        @start_sha = start_sha
        @head_sha = head_sha
      end

      def ==(other)
        other.is_a?(self.class) &&
          base_sha == other.base_sha &&
          start_sha == other.start_sha &&
          head_sha == other.head_sha
      end

      # There is only one case in which we will have `start_sha` and `head_sha`,
      # but not `base_sha`, which is when a diff is generated between an
      # orphaned branch and another branch, which means there _is_ no base, but
      # we're still able to highlight it, and to create diff notes, which are
      # the primary things `DiffRefs` are used for.
      # `DiffRefs` are "complete" when they have `start_sha` and `head_sha`,
      # because `base_sha` can always be derived from this, to return an actual
      # sha, or `nil`.
      # We have `base_sha` directly available on `DiffRefs` because it's faster#
      # than having to look it up in the repo every time.
      def complete?
        start_sha && head_sha
      end
    end
  end
end
