module Gitlab
  module Conflict
    class File
      include Gitlab::Routing
      include IconsHelper

      CONTEXT_LINES = 3

      attr_reader :merge_request

      # 'raw' holds the Gitlab::Git::Conflict::File that this instance wraps
      attr_reader :raw

      delegate :type, :content, :their_path, :our_path, :our_mode, :our_blob, :repository, to: :raw

      def initialize(raw, merge_request:)
        @raw = raw
        @merge_request = merge_request
        @match_line_headers = {}
      end

      def lines
        return @lines if defined?(@lines)

        @lines = raw.lines.nil? ? nil : map_raw_lines(raw.lines)
      end

      def resolve_lines(resolution)
        map_raw_lines(raw.resolve_lines(resolution))
      end

      def highlight_lines!
        their_file = lines.reject { |line| line.type == 'new' }.map(&:text).join("\n")
        our_file = lines.reject { |line| line.type == 'old' }.map(&:text).join("\n")

        their_highlight = Gitlab::Highlight.highlight(their_path, their_file, repository: repository).lines
        our_highlight = Gitlab::Highlight.highlight(our_path, our_file, repository: repository).lines

        lines.each do |line|
          line.rich_text =
            if line.type == 'old'
              their_highlight[line.old_line - 1].try(:html_safe)
            else
              our_highlight[line.new_line - 1].try(:html_safe)
            end
        end
      end

      def sections
        return @sections if @sections

        chunked_lines = lines.chunk { |line| line.type.nil? }.to_a
        match_line = nil

        sections_count = chunked_lines.size

        @sections = chunked_lines.flat_map.with_index do |(no_conflict, lines), i|
          section = nil

          # We need to reduce context sections to CONTEXT_LINES. Conflict sections are
          # always shown in full.
          if no_conflict
            conflict_before = i > 0
            conflict_after = (sections_count - i) > 1

            if conflict_before && conflict_after
              # Create a gap in a long context section.
              if lines.length > CONTEXT_LINES * 2
                head_lines = lines.first(CONTEXT_LINES)
                tail_lines = lines.last(CONTEXT_LINES)

                # Ensure any existing match line has text for all lines up to the last
                # line of its context.
                update_match_line_text(match_line, head_lines.last)

                # Insert a new match line after the created gap.
                match_line = create_match_line(tail_lines.first)

                section = [
                  { conflict: false, lines: head_lines },
                  { conflict: false, lines: tail_lines.unshift(match_line) }
                ]
              end
            elsif conflict_after
              tail_lines = lines.last(CONTEXT_LINES)

              # Create a gap and insert a match line at the start.
              if lines.length > tail_lines.length
                match_line = create_match_line(tail_lines.first)

                tail_lines.unshift(match_line)
              end

              lines = tail_lines
            elsif conflict_before
              # We're at the end of the file (no conflicts after), so just remove extra
              # trailing lines.
              lines = lines.first(CONTEXT_LINES)
            end
          end

          # We want to update the match line's text every time unless we've already
          # created a gap and its corresponding match line.
          update_match_line_text(match_line, lines.last) unless section

          section ||= { conflict: !no_conflict, lines: lines }
          section[:id] = line_code(lines.first) unless no_conflict
          section
        end
      end

      def line_code(line)
        Gitlab::Git.diff_line_code(our_path, line.new_pos, line.old_pos)
      end

      def create_match_line(line)
        Gitlab::Diff::Line.new('', 'match', line.index, line.old_pos, line.new_pos)
      end

      # Any line beginning with a letter, an underscore, or a dollar can be used in a
      # match line header. Only context sections can contain match lines, as match lines
      # have to exist in both versions of the file.
      def find_match_line_header(index)
        return @match_line_headers[index] if @match_line_headers.key?(index)

        @match_line_headers[index] = begin
          if index >= 0
            line = lines[index]

            if line.type.nil? && line.text.match(/\A[A-Za-z$_]/)
              " #{line.text}"
            else
              find_match_line_header(index - 1)
            end
          end
        end
      end

      # Set the match line's text for the current line. A match line takes its start
      # position and context header (where present) from itself, and its end position from
      # the line passed in.
      def update_match_line_text(match_line, line)
        return unless match_line

        header = find_match_line_header(match_line.index - 1)

        match_line.text = "@@ -#{match_line.old_pos},#{line.old_pos} +#{match_line.new_pos},#{line.new_pos} @@#{header}"
      end

      def as_json(opts = {})
        json_hash = {
          old_path: their_path,
          new_path: our_path,
          blob_icon: file_type_icon_class('file', our_mode, our_path),
          blob_path: project_blob_path(merge_request.project, ::File.join(merge_request.diff_refs.head_sha, our_path))
        }

        json_hash.tap do |json_hash|
          if opts[:full_content]
            json_hash[:content] = content
            json_hash[:blob_ace_mode] = our_blob && our_blob.language.try(:ace_mode)
          else
            json_hash[:sections] = sections if type.text?
            json_hash[:type] = type
            json_hash[:content_path] = content_path
          end
        end
      end

      def content_path
        conflict_for_path_project_merge_request_path(merge_request.project,
                                                     merge_request,
                                                     old_path: their_path,
                                                     new_path: our_path)
      end

      private

      def map_raw_lines(raw_lines)
        raw_lines.map do |raw_line|
          Gitlab::Diff::Line.new(raw_line[:full_line], raw_line[:type],
            raw_line[:line_obj_index], raw_line[:line_old],
            raw_line[:line_new], parent_file: self)
        end
      end
    end
  end
end
