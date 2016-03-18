module Gitlab
  module Diff
    class Parser
      include Enumerable

      def parse(lines)
        @lines = lines
        line_obj_index = 0
        line_old = 1
        line_new = 1
        type = nil

        # By returning an Enumerator we make it possible to search for a single line (with #find)
        # without having to instantiate all the others that come after it.
        Enumerator.new do |yielder|
          @lines.each do |line|
            next if filename?(line)
  
            full_line = line.gsub(/\n/, '')
  
            if line.match(/^@@ -/)
              type = "match"
  
              line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
              line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0
  
              next if line_old <= 1 && line_new <= 1 #top of file
              yielder << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new)
              line_obj_index += 1
              next
            elsif line[0] == '\\'
              type = 'nonewline'
              yielder << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new)
              line_obj_index += 1
            else
              type = identification_type(line)
              yielder << Gitlab::Diff::Line.new(full_line, type, line_obj_index, line_old, line_new)
              line_obj_index += 1
            end
  
  
            case line[0]
            when "+"
              line_new += 1
            when "-"
              line_old += 1
            when "\\"
              # No increment
            else
              line_new += 1
              line_old += 1
            end
          end
        end
      end

      def empty?
        @lines.empty?
      end

      private

      def filename?(line)
        line.start_with?( '--- /dev/null', '+++ /dev/null', '--- a', '+++ b',
                          '+++ a', # The line will start with `+++ a` in the reverse diff of an orphan commit
                          '--- /tmp/diffy', '+++ /tmp/diffy')
      end

      def identification_type(line)
        case line[0]
        when "+"
          "new"
        when "-"
          "old"
        else
          nil
        end
      end
    end
  end
end
