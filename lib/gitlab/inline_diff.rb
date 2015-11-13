module Gitlab
  class InlineDiff
    class << self

      START  = "#!idiff-start!#"
      FINISH = "#!idiff-finish!#"

      def processing(diff_arr)
        indexes = _indexes_of_changed_lines diff_arr

        indexes.each do |index|
          first_line = diff_arr[index+1]
          second_line = diff_arr[index+2]

          # Skip inline diff if empty line was replaced with content
          next if first_line == "-\n"

          first_token = find_first_token(first_line, second_line)
          apply_first_token(diff_arr, index, first_token)

          last_token = find_last_token(first_line, second_line, first_token)
          apply_last_token(diff_arr, index, last_token)
        end

        diff_arr
      end

      def apply_first_token(diff_arr, index, first_token)
        start = first_token + START

        if first_token.empty?
          # In case if we remove string of spaces in commit
          diff_arr[index+1].sub!("-", "-" => "-#{START}")
          diff_arr[index+2].sub!("+", "+" => "+#{START}")
        else
          diff_arr[index+1].sub!(first_token, first_token => start)
          diff_arr[index+2].sub!(first_token, first_token => start)
        end
      end

      def apply_last_token(diff_arr, index, last_token)
        # This is tricky: escape backslashes so that `sub` doesn't interpret them
        # as backreferences. Regexp.escape does NOT do the right thing.
        replace_token = FINISH + last_token.gsub(/\\/, '\&\&')
        diff_arr[index+1].sub!(/#{Regexp.escape(last_token)}$/, replace_token)
        diff_arr[index+2].sub!(/#{Regexp.escape(last_token)}$/, replace_token)
      end

      def find_first_token(first_line, second_line)
        max_length = [first_line.size, second_line.size].max
        first_the_same_symbols = 0

        (0..max_length + 1).each do |i|
          first_the_same_symbols = i - 1

          if first_line[i] != second_line[i] && i > 0
            break
          end
        end

        first_line[0..first_the_same_symbols][1..-1]
      end

      def find_last_token(first_line, second_line, first_token)
        max_length = [first_line.size, second_line.size].max
        last_the_same_symbols = 0

        (1..max_length + 1).each do |i|
          last_the_same_symbols = -i
          shortest_line = second_line.size > first_line.size ? first_line : second_line

          if (first_line[-i] != second_line[-i]) || "#{first_token}#{START}".size == shortest_line[1..-i].size
            break
          end
        end

        last_the_same_symbols += 1
        first_line[last_the_same_symbols..-1]
      end

      def _indexes_of_changed_lines(diff_arr)
        chain_of_first_symbols = ""
        diff_arr.each_with_index do |line, i|
          chain_of_first_symbols += line[0]
        end
        chain_of_first_symbols.gsub!(/[^\-\+]/, "#")

        offset = 0
        indexes = []
        while index = chain_of_first_symbols.index("#-+#", offset)
          indexes << index
          offset = index + 1
        end
        indexes
      end

      def replace_markers(line)
        line.gsub!(START, "<span class='idiff'>")
        line.gsub!(FINISH, "</span>")
        line
      end
    end
  end
end
