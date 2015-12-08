module Gitlab
  module Diff
    class Parser
      include Enumerable

      def parse(lines)
        @lines = lines
        lines_obj = []
        line_obj_index = 0
        line_old = 1
        line_new = 1
        type = nil

        lines_arr = ::Gitlab::InlineDiff.processing lines

        lines_arr.each do |line|
          next if filename?(line)

          full_line = html_escape(line.gsub(/\n/, ''))
          full_line = ::Gitlab::InlineDiff.replace_markers full_line

          if line.match(/^@@ -/)
            type = "match"

            line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
            line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0

            next if line_old <= 1 && line_new <= 1 #top of file
            lines_obj << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new)
            line_obj_index += 1
            next
          else
            type = identification_type(line)
            lines_obj << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new)
            line_obj_index += 1
          end


          if line[0] == "+"
            line_new += 1
          elsif line[0] == "-"
            line_old += 1
          else
            line_new += 1
            line_old += 1
          end
        end

        lines_obj
      end

      def empty?
        @lines.empty?
      end

      private

      def filename?(line)
        line.start_with?('--- /dev/null', '+++ /dev/null', '--- a', '+++ b',
                         '--- /tmp/diffy', '+++ /tmp/diffy')
      end

      def identification_type(line)
        if line[0] == "+"
          "new"
        elsif line[0] == "-"
          "old"
        else
          nil
        end
      end

      def html_escape(str)
        replacements = { '&' => '&amp;', '>' => '&gt;', '<' => '&lt;', '"' => '&quot;', "'" => '&#39;' }
        str.gsub(/[&"'><]/, replacements)
      end
    end
  end
end
