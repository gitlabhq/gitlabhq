module Gitlab
  class InlineDiff
    class << self

      START  = "#!idiff-start!#"
      FINISH = "#!idiff-finish!#"
    
      def processing diff_arr
        indexes = _indexes_of_changed_lines diff_arr

        indexes.each do |index|
          first_line = diff_arr[index+1]
          second_line = diff_arr[index+2]
          max_length = [first_line.size, second_line.size].max

          first_the_same_symbols = 0
          (0..max_length + 1).each do |i|
            first_the_same_symbols = i - 1
            if first_line[i] != second_line[i] && i > 0
              break
            end
          end
          first_token = first_line[0..first_the_same_symbols][1..-1]
          diff_arr[index+1].sub!(first_token, first_token + START)
          diff_arr[index+2].sub!(first_token, first_token + START)
          last_the_same_symbols = 0
          (1..max_length + 1).each do |i|
            last_the_same_symbols = -i
            shortest_line = second_line.size > first_line.size ? first_line : second_line
            if ( first_line[-i] != second_line[-i] ) || "#{first_token}#{START}".size == shortest_line[1..-i].size
              break
            end
          end
          last_the_same_symbols += 1
          last_token = first_line[last_the_same_symbols..-1]
          diff_arr[index+1].sub!(/#{Regexp.escape(last_token)}$/, FINISH + last_token)
          diff_arr[index+2].sub!(/#{Regexp.escape(last_token)}$/, FINISH + last_token)
        end
        diff_arr
      end

      def _indexes_of_changed_lines diff_arr
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

      def replace_markers line
        line.gsub!(START, "<span class='idiff'>")
        line.gsub!(FINISH, "</span>")
        line
      end
    
    end

  end
end
