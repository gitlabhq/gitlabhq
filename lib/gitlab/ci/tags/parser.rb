# frozen_string_literal: true

module Gitlab
  module Ci
    module Tags
      class Parser
        def initialize(tag_list)
          @tag_list = tag_list
        end

        def parse
          string = @tag_list

          string = string.join(', ') if string.respond_to?(:join)
          TagList.new.tap do |tag_list|
            string = string.to_s.dup

            string.gsub!(double_quote_pattern) do
              # Append the matched tag to the tag list
              tag_list << Regexp.last_match[2]
              # Return the matched delimiter ($3) to replace the matched items
              ''
            end

            string.gsub!(single_quote_pattern) do
              # Append the matched tag ($2) to the tag list
              tag_list << Regexp.last_match[2]
              # Return an empty string to replace the matched items
              ''
            end

            # split the string by the delimiter
            # and add to the tag_list
            tag_list.add(string.split(Regexp.new(delimiter)))
          end
        end

        private

        def delimiter
          ','
        end

        # (             # Tag start delimiter ($1)
        # \A       |  # Either string start or
        # #{delimiter}        # a delimiter
        # )
        # \s*"          # quote (") optionally preceded by whitespace
        # (.*?)         # Tag ($2)
        # "\s*          # quote (") optionally followed by whitespace
        # (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
        # #{delimiter}\s*  |  # Either a delimiter optionally followed by whitespace or
        # \z          # string end
        # )
        def double_quote_pattern
          /(\A|#{delimiter})\s*"(.*?)"\s*(?=#{delimiter}\s*|\z)/
        end

        # (             # Tag start delimiter ($1)
        # \A       |  # Either string start or
        # #{delimiter}        # a delimiter
        # )
        # \s*'          # quote (') optionally preceded by whitespace
        # (.*?)         # Tag ($2)
        # '\s*          # quote (') optionally followed by whitespace
        # (?=           # Tag end delimiter (not consumed; is zero-length lookahead)
        # #{delimiter}\s*  | d # Either a delimiter optionally followed by whitespace or
        # \z          # string end
        # )
        def single_quote_pattern
          /(\A|#{delimiter})\s*'(.*?)'\s*(?=#{delimiter}\s*|\z)/
        end
      end
    end
  end
end
