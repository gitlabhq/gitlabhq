module Gitlab
  class DiffParser
    include Enumerable

    attr_reader :lines, :new_path

    def initialize(lines, new_path = '')
      @lines = lines
      @new_path = new_path
    end

    def each
      line_old = 1
      line_new = 1
      type = nil

      lines_arr = ::Gitlab::InlineDiff.processing lines
      lines_arr.each do |line|
        raw_line = line.dup

        next if filename?(line)

        full_line = html_escape(line.gsub(/\n/, ''))
        full_line = ::Gitlab::InlineDiff.replace_markers full_line

        if line.match(/^@@ -/)
          type = "match"

          line_old = line.match(/\-[0-9]*/)[0].to_i.abs rescue 0
          line_new = line.match(/\+[0-9]*/)[0].to_i.abs rescue 0

          next if line_old == 1 && line_new == 1 #top of file
          yield(full_line, type, nil, nil, nil)
          next
        else
          type = identification_type(line)
          line_code = generate_line_code(new_path, line_new, line_old)
          yield(full_line, type, line_code, line_new, line_old, raw_line)
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

    def generate_line_code(path, line_new, line_old)
      "#{Digest::SHA1.hexdigest(path)}_#{line_old}_#{line_new}"
    end

    def html_escape str
      replacements = { '&' => '&amp;', '>' => '&gt;', '<' => '&lt;', '"' => '&quot;', "'" => '&#39;' }
        str.gsub(/[&"'><]/, replacements)
    end
  end
end
