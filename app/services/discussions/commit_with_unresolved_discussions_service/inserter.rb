module Discussions
  class CommitWithUnresolvedDiscussionsService
    class Inserter
      attr_reader :blob

      def initialize(blob)
        @blob = blob
      end

      def insert(insertions)
        commenter = Commenter.for_blob(blob)

        line_offset = 0
        insertions.sort.each do |insertion|
          insertion_length = insertion.insert(lines, commenter, offset: line_offset)
          line_offset += insertion_length
        end

        lines.join
      end

      private

      def lines
        @lines ||= begin
          blob.load_all_data!

          content = blob.data
          content += "\n" unless content.end_with?("\n")
          content.lines
        end
      end
    end
  end
end
