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

      # Corresponds to the "$$\n...\n$$" syntax
      REGEX = %r{
          #{::Gitlab::Regex.markdown_code_or_html_blocks}
        |
          (?=(?<=^\n|\A)\$\$\ *\n.*\n\$\$\ *(?=\n$|\z))(?:
            # Display math block:
            # $$
            # latex math
            # $$

            (?<=^\n|\A)\$\$\ *\n
            (?<display_math>
              (?:.)+?
            )
            \n\$\$\ *(?=\n$|\z)
          )
      }mx.freeze

      def call
        @text.gsub(REGEX) do
          if $~[:display_math]
            # change from $$ to ```math
            "```math\n#{$~[:display_math]}\n```"
          else
            $~[0]
          end
        end
      end
    end
  end
end
