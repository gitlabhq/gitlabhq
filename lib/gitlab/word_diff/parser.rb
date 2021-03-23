# frozen_string_literal: true

# Converts git diff --word-diff=porcelain output to Gitlab::Diff::Line objects
# see: https://git-scm.com/docs/git-diff#Documentation/git-diff.txt-porcelain
module Gitlab
  module WordDiff
    class Parser
      include Enumerable

      def parse(lines, diff_file: nil)
        return [] if lines.blank?

        # By returning an Enumerator we make it possible to search for a single line (with #find)
        # without having to instantiate all the others that come after it.
        Enumerator.new do |yielder|
          @chunks = ChunkCollection.new
          @counter = PositionsCounter.new

          lines.each do |line|
            segment = LineProcessor.new(line).extract

            case segment
            when Segments::DiffHunk
              next if segment.first_line?

              counter.set_pos_num(old: segment.pos_old, new: segment.pos_new)

              yielder << build_line(segment.to_s, 'match', parent_file: diff_file)

            when Segments::Chunk
              @chunks.add(segment)

            when Segments::Newline
              yielder << build_line(@chunks.content, nil, parent_file: diff_file).tap { |line| line.set_marker_ranges(@chunks.marker_ranges) }

              @chunks.reset
              counter.increase_pos_num
            end
          end
        end
      end

      private

      attr_reader :counter

      def build_line(content, type, options = {})
        Gitlab::Diff::Line.new(
          content, type,
          counter.line_obj_index, counter.pos_old, counter.pos_new,
          **options).tap do
          counter.increase_obj_index
        end
      end
    end
  end
end
