# frozen_string_literal: true

module Gitlab
  module Conflict
    class File
      include Gitlab::Routing
      include IconsHelper
      include Gitlab::Utils::StrongMemoize

      CONTEXT_LINES = 3

      CONFLICT_MARKER_OUR = 'conflict_marker_our'
      CONFLICT_MARKER_THEIR = 'conflict_marker_their'
      CONFLICT_MARKER_SEPARATOR = 'conflict_marker'

      CONFLICT_TYPES = {
        "old" => "conflict_their",
        "new" => "conflict_our"
      }.freeze

      attr_reader :merge_request

      # 'raw' holds the Gitlab::Git::Conflict::File that this instance wraps
      attr_reader :raw

      delegate :type, :content, :path, :ancestor_path, :their_path, :our_path, :our_mode, :our_blob, :repository, to: :raw

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
        their_highlight = Gitlab::Highlight.highlight(their_path, their_lines, language: their_language).lines
        our_highlight = Gitlab::Highlight.highlight(our_path, our_lines, language: our_language).lines

        lines.each do |line|
          line.rich_text =
            if line.type == 'old'
              their_highlight[line.old_line - 1].try(:html_safe)
            else
              our_highlight[line.new_line - 1].try(:html_safe)
            end
        end
      end

      def diff_lines_for_serializer
        # calculate sections and highlight lines before changing types
        sections && highlight_lines!

        sections.flat_map do |section|
          if section[:conflict]
            lines = []

            lines << create_separator_line(section[:lines].first, CONFLICT_MARKER_OUR)

            current_type = section[:lines].first.type
            section[:lines].each do |line|
              if line.type != current_type # insert a separator between our changes and theirs
                lines << create_separator_line(line, CONFLICT_MARKER_SEPARATOR)
                current_type = line.type
              end

              line.type = CONFLICT_TYPES[line.type]

              # Swap the positions around due to conflicts/diffs display inconsistency
              # https://gitlab.com/gitlab-org/gitlab/-/issues/291989
              line.old_pos, line.new_pos = line.new_pos, line.old_pos

              lines << line
            end

            lines << create_separator_line(lines.last, CONFLICT_MARKER_THEIR)

            lines
          else
            section[:lines]
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
              # We're at the end of the file (no conflicts after)
              number_of_trailing_lines = lines.size

              # Remove extra trailing lines
              lines = lines.first(CONTEXT_LINES)

              if number_of_trailing_lines > CONTEXT_LINES
                lines << create_match_line(lines.last)
              end
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

      def create_separator_line(line, type)
        Gitlab::Diff::Line.new('', type, line.index, nil, nil)
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

      def conflict_type(when_renamed: false)
        if ancestor_path.present?
          if our_path.present? && their_path.present?
            :both_modified
          elsif their_path.blank?
            :modified_source_removed_target
          else
            :modified_target_removed_source
          end
        elsif our_path.present? && their_path.present?
          :both_added
        elsif their_path.blank?
          when_renamed ? :renamed_same_file : :removed_target_renamed_source
        else
          :removed_source_renamed_target
        end
      end

      private

      def map_raw_lines(raw_lines)
        raw_lines.map do |raw_line|
          Gitlab::Diff::Line.new(raw_line[:full_line], raw_line[:type],
            raw_line[:line_obj_index], raw_line[:line_old],
            raw_line[:line_new], parent_file: self)
        end
      end

      def their_language
        strong_memoize(:their_language) do
          repository.gitattribute(their_path, 'gitlab-language')
        end
      end

      def our_language
        strong_memoize(:our_language) do
          if our_path == their_path
            their_language
          else
            repository.gitattribute(our_path, 'gitlab-language')
          end
        end
      end

      def their_lines
        strong_memoize(:their_lines) do
          lines.reject { |line| line.type == 'new' }.map(&:text).join("\n")
        end
      end

      def our_lines
        strong_memoize(:our_lines) do
          lines.reject { |line| line.type == 'old' }.map(&:text).join("\n")
        end
      end
    end
  end
end
