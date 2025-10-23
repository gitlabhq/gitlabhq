# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks define a valid success response
      #
      # @example
      #
      #   # bad
      #   desc 'Get a specific thing' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     tags ['things']
      #     ...
      #   end
      #
      #   # bad
      #   desc 'Get a specific thing' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     http_codes [[204, 'Thing was deleted'], [403, 'Forbidden']]
      #     tags ['things']
      #     ...
      #   end

      #   # good
      #   desc 'Get a specific thing' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success Entities::Thing
      #     tags ['things']
      #     ...
      #   end
      #
      #   # good
      #   desc 'Get a specific thing' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success code: 204, message: 'Thing was deleted'
      #     failure [{ code: 403, message: 'Forbidden' }]
      #     tags ['things']
      #     ...
      #   end
      class DescriptionSuccessResponse < RuboCop::Cop::Base
        include CodeReuseHelpers

        MSG = 'API desc blocks must define a success response. https://docs.gitlab.com/development/api_styleguide/#defining-endpoint-success.'

        # @!method has_success_response?(node)
        def_node_matcher :has_success_response?, '`(send nil? :success ...)'

        def on_block(node)
          return unless node.method?(:desc)
          return if has_success_response?(node)

          add_offense(node)
        end

        alias_method :on_numblock, :on_block
      end
    end
  end
end
