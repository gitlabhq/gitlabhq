module MergeRequests
  module Conflicts
    class ResolverService
      attr_accessor :merge_request

      def initialize(merge_request)
        @merge_request = merge_request
      end

      def conflicts
        return [] unless @merge_request.conflicts?

        diff_lines = []

        @merge_request.conflicts.each do |c|
          diff_lines.push(
            Gitlab::Diff::Parser.new.parse(
              @merge_request.conflict_diff(c).each_line.collect { |el| el.content }
            ).to_a
          )
        end

        diff_lines
      end
    end
  end
end
