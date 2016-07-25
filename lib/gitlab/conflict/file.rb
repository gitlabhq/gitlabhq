module Gitlab
  module Conflict
    class File
      CONTEXT_LINES = 3

      attr_reader :merge_file, :their_path, :their_ref, :our_path, :our_ref, :repository

      def initialize(merge_file, conflict, their_ref, our_ref, repository)
        @merge_file = merge_file
        @their_path = conflict[:theirs][:path]
        @our_path = conflict[:ours][:path]
        @their_ref = their_ref
        @our_ref = our_ref
        @repository = repository
      end

      # Array of Gitlab::Diff::Line objects
      def lines
        @lines ||= Gitlab::Conflict::Parser.new.parse(merge_file[:data], their_path, our_path)
      end

      def highlighted_lines
        return @highlighted_lines if @highlighted_lines

        their_highlight = Gitlab::Highlight.highlight_lines(repository, their_ref, their_path)
        our_highlight = Gitlab::Highlight.highlight_lines(repository, our_ref, our_path)

        @highlighted_lines = lines.map do |line|
          line = line.dup
          if line.type == 'old'
            line.rich_text = their_highlight[line.old_line - 1].delete("\n")
          else
            line.rich_text = our_highlight[line.new_line - 1].delete("\n")
          end
          line
        end
      end

      def sections
        return @sections if @sections

        chunked_lines = highlighted_lines.chunk { |line| line.type.nil? }
        match_line = nil

        @sections = chunked_lines.flat_map.with_index do |(no_conflict, lines), i|
          section = nil

          if no_conflict
            conflict_before = i > 0
            conflict_after = chunked_lines.peek

            if conflict_before && conflict_after
              if lines.length > CONTEXT_LINES * 2
                tail_lines = lines.last(CONTEXT_LINES)
                first_tail_line = tail_lines.first
                match_line = Gitlab::Diff::Line.new('',
                                                    'match',
                                                    first_tail_line.index,
                                                    first_tail_line.old_pos,
                                                    first_tail_line.new_pos)

                section = [
                  { conflict: false, lines: lines.first(CONTEXT_LINES) },
                  { conflict: false, lines: tail_lines.unshift(match_line) }
                ]
              end
            elsif conflict_after
              lines = lines.last(CONTEXT_LINES)
            elsif conflict_before
              lines = lines.first(CONTEXT_LINES)
            end
          end

          if match_line && !section
            match_line.text = "@@ -#{match_line.old_pos},#{lines.last.old_pos} +#{match_line.new_pos},#{lines.last.new_pos} @@"
          end

          section || { conflict: !no_conflict, lines: lines }
        end
      end

      def as_json(opts = nil)
        {
          old_path: their_path,
          new_path: our_path,
          sections: sections
        }
      end
    end
  end
end
