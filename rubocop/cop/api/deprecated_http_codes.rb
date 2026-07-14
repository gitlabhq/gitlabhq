# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks do not use the deprecated `http_codes` declaration.
      #
      # `http_codes` declares success and failure responses in a single array, which is
      # semantically confusing. Use `success` and `failure` instead.
      #
      # @example
      #
      #   # bad
      #   desc 'Delete a thing' do
      #     http_codes [[204, 'Thing was deleted'], [403, 'Forbidden']]
      #     tags ['things']
      #   end
      #
      #   # good
      #   desc 'Delete a thing' do
      #     success [{ code: 204, message: 'Thing was deleted' }]
      #     failure [{ code: 403, message: 'Forbidden' }]
      #     tags ['things']
      #   end
      class DeprecatedHttpCodes < RuboCop::Cop::Base
        MSG = 'Do not use `http_codes` in API desc blocks. Use `success`/ `failure` instead. ' \
          'https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-success.'

        # @!method http_codes_declarations(node)
        def_node_search :http_codes_declarations, '$(send nil? :http_codes ...)'

        def on_block(node)
          return unless node.method?(:desc)

          http_codes_declarations(node) do |http_codes_node|
            add_offense(http_codes_node)
          end
        end

        alias_method :on_numblock, :on_block
      end
    end
  end
end
