# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # This cop is based on `Style/RegexpLiteral` but adds a new
      # `EnforcedStyle` option `mixed_preserve`.
      #
      # This cop will be removed once the upstream PR is merged and RuboCop upgraded.
      #
      # See https://github.com/rubocop/rubocop/pull/9688
      class RegexpLiteralMixedPreserve < RuboCop::Cop::Style::RegexpLiteral
        module Patch
          private

          def allowed_slash_literal?(node)
            super || allowed_mixed_preserve?(node)
          end

          def allowed_percent_r_literal?(node)
            super || allowed_mixed_preserve?(node)
          end

          def allowed_mixed_preserve?(node)
            style == :mixed_preserve && !contains_disallowed_slash?(node)
          end
        end

        prepend Patch
      end
    end
  end
end
