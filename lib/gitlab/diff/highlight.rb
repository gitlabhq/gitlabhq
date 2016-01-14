module Gitlab
  module Diff
    class Highlight
      attr_reader :diff_file

      delegate :repository, :old_path, :new_path, :old_ref, :new_ref,
        to: :diff_file, prefix: :diff

      # Apply syntax highlight to provided source code
      #
      # diff_file - an instance of Gitlab::Diff::File
      #
      # Returns an Array with the processed items.
      def self.process_diff_lines(diff_file)
        processor = new(diff_file)
        processor.highlight
      end

      def self.process_file(repository, ref, file_name)
        blob = repository.blob_at(ref, file_name)
        return [] unless blob

        Gitlab::Highlight.highlight(file_name, blob.data).lines.map!(&:html_safe)
      end

      def initialize(diff_file)
        @diff_file = diff_file
        @file_name = diff_file.new_path
        @lines     = diff_file.diff_lines
      end

      def highlight
        return [] if @lines.empty?

        @lines.each_with_index do |line, i|
          line_prefix = line.text.match(/\A([+-])/) ? $1 : ' '

          # ignore highlighting for "match" lines
          next if line.type == 'match'

          case line.type
          when 'new', nil
            highlighted_line = new_lines[line.new_pos - 1]
          when 'old'
            highlighted_line = old_lines[line.old_pos - 1]
          end

          # Only update text if line is found. This will prevent
          # issues with submodules given the line only exists in diff content.
          line.text = highlighted_line.insert(0, line_prefix).html_safe if highlighted_line
        end

        @lines
      end

      def old_lines
        @old_lines ||= self.class.process_file(diff_repository, diff_old_ref, diff_old_path)
      end

      def new_lines
        @new_lines ||= self.class.process_file(diff_repository, diff_new_ref, diff_new_path)
      end
    end
  end
end
