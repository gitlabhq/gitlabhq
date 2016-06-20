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

      def complete?
        start_sha && head_sha
      end
    end
  end
end
