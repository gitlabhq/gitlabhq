# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks do not contain DEPRECATED in the description string.
      # Instead, use `deprecated true` inside the desc block.
      #
      # @example
      #
      #   # bad
      #   desc "[DEPRECATED] Update a user's credit_card_validation" do
      #     success Entities::UserCreditCardValidations
      #     tags ['users']
      #   end
      #
      #   # good
      #   desc "Update a user's credit_card_validation" do
      #     detail 'Deprecated in GitLab 17.0'
      #     success Entities::UserCreditCardValidations
      #     tags ['users']
      #     deprecated true
      #   end
      class DeprecatedInDescription < RuboCop::Cop::Base
        include CodeReuseHelpers
        extend AutoCorrector

        MSG = 'Do not use DEPRECATED in API description. Use `deprecated true` inside the desc block instead. https://docs.gitlab.com/development/api_styleguide/#marking-endpoints-as-deprecated'

        DEPRECATED_PATTERN = /\[?DEPRECATED\]?\s*/i

        # @!method desc_block(node)
        def_node_matcher :desc_block, <<~PATTERN
          (block
            (send nil? :desc ${str dstr} ...)
            _args
            $_body
          )
        PATTERN

        # @!method has_deprecated?(node)
        def_node_matcher :has_deprecated?, <<~PATTERN
          `(send nil? :deprecated ...)
        PATTERN

        def on_block(node)
          return unless node.method?(:desc)

          summary_node, body = desc_block(node)
          return unless summary_node

          description_text = extract_description_text(summary_node)
          return unless description_text&.match?(DEPRECATED_PATTERN)

          add_offense(summary_node) do |corrector|
            autocorrect(corrector, node, summary_node, body)
          end
        end

        alias_method :on_numblock, :on_block

        private

        def extract_description_text(node)
          case node.type
          when :str
            node.value
          when :dstr
            node.children.select { |child| child.is_a?(Parser::AST::Node) && child.str_type? }
                .map(&:value).join
          end
        end

        def autocorrect(corrector, block_node, summary_node, body_node)
          corrector.replace(summary_node, corrected_description(summary_node))

          return if has_deprecated?(body_node)

          indentation = body_node ? indent(body_node) : "#{indent(block_node)}  "
          deprecated_line = "\n#{indentation}deprecated true"
          corrector.insert_after(body_node&.source_range || block_node.loc.begin, deprecated_line)
        end

        def corrected_description(node)
          case node.type
          when :str
            quote_char = node.source[0]
            new_value = node.value.gsub(DEPRECATED_PATTERN, '').strip
            "#{quote_char}#{new_value}#{quote_char}"
          when :dstr
            source = node.source
            source.gsub(DEPRECATED_PATTERN, '')
          end
        end
      end
    end
  end
end
