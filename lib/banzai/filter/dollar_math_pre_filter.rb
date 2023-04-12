# frozen_string_literal: true

# Generated HTML is transformed back to GFM by:
# - app/assets/javascripts/behaviors/markdown/marks/math.js
# - app/assets/javascripts/behaviors/markdown/nodes/code_block.js
module Banzai
  module Filter
    # HTML filter that implements our dollar math syntax, one of three filters:
    # DollarMathPreFilter, DollarMathPostFilter, and MathFilter
    #
    class DollarMathPreFilter < HTML::Pipeline::TextFilter
      # Based on the Pandoc heuristics,
      # https://pandoc.org/MANUAL.html#extension-tex_math_dollars
      #
      # Handle the $$\n...\n$$ syntax in this filter, before markdown processing,
      # by converting it into the ```math syntax. In this way, we can ensure
      # that it's considered a code block and will not have any markdown processed inside it.

      # Display math block:
      # $$
      # latex math
      # $$
      REGEX =
        "#{::Gitlab::Regex.markdown_code_or_html_blocks_or_html_comments_untrusted}" \
        '|' \
        '^\$\$\ *\n' \
        '(?P<display_math>' \
        '(?:\n|.)*?' \
        ')' \
        '\n\$\$\ *$' \
        .freeze

      def call
        regex = Gitlab::UntrustedRegexp.new(REGEX, multiline: true)
        return @text unless regex.match?(@text)

        regex.replace_gsub(@text) do |match|
          # change from $$ to ```math
          if match[:display_math]
            "```math\n#{match[:display_math]}\n```"
          else
            match.to_s
          end
        end
      end
    end
  end
end
