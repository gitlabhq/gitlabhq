module Gitlab
  module Conflict
    class File
      class MissingResolution < StandardError
      end

      CONTEXT_LINES = 3

      attr_reader :merge_file_result, :their_path, :their_ref, :our_path, :our_ref, :repository

      def initialize(merge_file_result, conflict, diff_refs:, repository:)
        @merge_file_result = merge_file_result
        @their_path = conflict[:theirs][:path]
        @our_path = conflict[:ours][:path]
        @their_ref = diff_refs.start_sha
        @our_ref = diff_refs.head_sha
        @repository = repository
      end

      # Array of Gitlab::Diff::Line objects
      def lines
        @lines ||= Gitlab::Conflict::Parser.new.parse(merge_file_result[:data],
                                                      our_path: our_path,
                                                      their_path: their_path,
                                                      parent: self)
      end

      def resolve!(resolution, index:, rugged:)
        new_file = resolve_lines(resolution).map(&:text).join("\n")

        oid = rugged.write(new_file, :blob)
        our_mode = index.conflict_get(our_path)[:ours][:mode]
        index.add(path: our_path, oid: oid, mode: our_mode)
        index.conflict_remove(our_path)
      end

      def resolve_lines(resolution)
        section_id = nil

        lines.map do |line|
          unless line.type
            section_id = nil
            next line
          end

          section_id ||= line_code(line)

          case resolution[section_id]
          when 'ours'
            next unless line.type == 'new'
          when 'theirs'
            next unless line.type == 'old'
          else
            raise MissingResolution, "Missing resolution for section ID: #{section_id}"
          end

          line
        end.compact
      end

      def highlight_lines!
        their_highlight = Gitlab::Highlight.highlight_lines(repository, their_ref, their_path)
        our_highlight = Gitlab::Highlight.highlight_lines(repository, our_ref, our_path)

        lines.each do |line|
          if line.type == 'old'
            line.rich_text = their_highlight[line.old_line - 1]
          else
            line.rich_text = our_highlight[line.new_line - 1]
          end
        end
      end

      def sections
        return @sections if @sections

        chunked_lines = lines.chunk { |line| line.type.nil? }
        last_candidate_match_header = nil
        match_line_header = nil
        match_line = nil

        @sections = chunked_lines.flat_map.with_index do |(no_conflict, lines), i|
          section = nil

          lines.each do |line|
            last_candidate_match_header = " #{line.text}" if line.text.match(/\A[A-Za-z$_]/)
          end

          if no_conflict
            conflict_before = i > 0
            conflict_after = chunked_lines.peek

            if conflict_before && conflict_after
              if lines.length > CONTEXT_LINES * 2
                tail_lines = lines.last(CONTEXT_LINES)
                first_tail_line = tail_lines.first
                match_line_header = last_candidate_match_header
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
            match_line.text = "@@ -#{match_line.old_pos},#{lines.last.old_pos} +#{match_line.new_pos},#{lines.last.new_pos} @@#{match_line_header}"
          end

          section ||= { conflict: !no_conflict, lines: lines }
          section[:id] = line_code(lines.first) unless no_conflict
          section
        end
      end

      def line_code(line)
        Gitlab::Diff::LineCode.generate(our_path, line.new_pos, line.old_pos)
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
