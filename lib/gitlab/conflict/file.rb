module Gitlab
  module Conflict
    class File
      include Gitlab::Routing.url_helpers

      class MissingResolution < StandardError
      end

      CONTEXT_LINES = 3

      attr_reader :merge_file_result, :their_path, :our_path, :merge_request, :repository

      def initialize(merge_file_result, conflict, merge_request:)
        @merge_file_result = merge_file_result
        @their_path = conflict[:theirs][:path]
        @our_path = conflict[:ours][:path]
        @merge_request = merge_request
        @repository = merge_request.project.repository
      end

      # Array of Gitlab::Diff::Line objects
      def lines
        @lines ||= Gitlab::Conflict::Parser.new.parse(merge_file_result[:data],
                                                      our_path: our_path,
                                                      their_path: their_path,
                                                      parent_file: self)
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
          when 'head'
            next unless line.type == 'new'
          when 'origin'
            next unless line.type == 'old'
          else
            raise MissingResolution, "Missing resolution for section ID: #{section_id}"
          end

          line
        end.compact
      end

      def highlight_lines!
        their_file = lines.reject { |line| line.type == 'new' }.map(&:text).join("\n")
        our_file = lines.reject { |line| line.type == 'old' }.map(&:text).join("\n")

        their_highlight = Gitlab::Highlight.highlight(their_path, their_file, repository: repository).lines
        our_highlight = Gitlab::Highlight.highlight(our_path, our_file, repository: repository).lines

        lines.each do |line|
          if line.type == 'old'
            line.rich_text = their_highlight[line.old_line - 1].html_safe
          else
            line.rich_text = our_highlight[line.new_line - 1].html_safe
          end
        end
      end

      def sections
        return @sections if @sections

        candidate_match_headers = lines.map do |line|
          " #{line.text}" if line.text.match(/\A[A-Za-z$_]/) && line.type.nil?
        end

        chunked_lines = lines.chunk { |line| line.type.nil? }
        match_line = nil

        @sections = chunked_lines.flat_map.with_index do |(no_conflict, lines), i|
          section = nil

          if no_conflict
            conflict_before = i > 0
            conflict_after = chunked_lines.peek

            if conflict_before && conflict_after
              if lines.length > CONTEXT_LINES * 2
                head_lines = lines.first(CONTEXT_LINES)
                tail_lines = lines.last(CONTEXT_LINES)

                update_match_line_text(match_line, head_lines.last, candidate_match_headers)

                match_line = create_match_line(tail_lines.first)
                update_match_line_text(match_line, tail_lines.last, candidate_match_headers)

                section = [
                  { conflict: false, lines: head_lines },
                  { conflict: false, lines: tail_lines.unshift(match_line) }
                ]
              end
            elsif conflict_after
              tail_lines = lines.last(CONTEXT_LINES)

              if lines.length > CONTEXT_LINES
                match_line = create_match_line(tail_lines.first)

                tail_lines.unshift(match_line)
              end

              lines = tail_lines
            elsif conflict_before
              lines = lines.first(CONTEXT_LINES)
            end
          end

          update_match_line_text(match_line, lines.last, candidate_match_headers) unless section

          section ||= { conflict: !no_conflict, lines: lines }
          section[:id] = line_code(lines.first) unless no_conflict
          section
        end
      end

      def line_code(line)
        Gitlab::Diff::LineCode.generate(our_path, line.new_pos, line.old_pos)
      end

      def create_match_line(line)
        Gitlab::Diff::Line.new('', 'match', line.index, line.old_pos, line.new_pos)
      end

      def update_match_line_text(match_line, line, headers)
        return unless match_line

        header = headers.first(line.index).compact.last

        match_line.text = "@@ -#{match_line.old_pos},#{line.old_pos} +#{match_line.new_pos},#{line.new_pos} @@#{header}"
      end

      def as_json(opts = nil)
        {
          old_path: their_path,
          new_path: our_path,
          blob_path: namespace_project_blob_path(merge_request.project.namespace,
                                                 merge_request.project,
                                                 ::File.join(merge_request.diff_refs.head_sha, our_path)),
          sections: sections
        }
      end
    end
  end
end
