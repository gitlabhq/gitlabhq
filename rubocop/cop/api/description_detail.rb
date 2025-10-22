# frozen_string_literal: true

require_relative '../../code_reuse_helpers'

module RuboCop
  module Cop
    module API
      # Checks that API desc blocks define a valid detail
      #
      # @example
      #
      #   # bad (no detail given)
      #   desc 'Get a specific environment' do
      #     success Entities::Environment
      #     ...
      #   end
      #
      #   # bad (invalid detail not a string)
      #   desc 'Get a specific environment' do
      #     detail ['Foo bar baz bat', 'http://example.com']
      #     success Entities::Environment
      #     ...
      #   end
      #
      #   # good
      #   desc 'Get a specific environment' do
      #     detail 'This feature was introduced in GitLab 18.2.'
      #     success Entities::Environment
      #     ...
      #   end
      class DescriptionDetail < RuboCop::Cop::Base
        include CodeReuseHelpers

        MSG = 'API desc blocks must define a valid detail string. https://docs.gitlab.com/development/api_styleguide#defining-endpoint-details.'

        # @!method has_valid_detail?(node)
        def_node_matcher :has_valid_detail?, '`(send nil? :detail {(str _) (dstr ...)})'

        def on_block(node)
          return unless node.method?(:desc)
          return if has_valid_detail?(node)

          add_offense(node)
        end

        alias_method :on_numblock, :on_block
      end
    end
  end
end
