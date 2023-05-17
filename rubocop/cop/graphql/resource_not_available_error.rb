# frozen_string_literal: true

require_relative '../../node_pattern_helper'

module RuboCop
  module Cop
    module Graphql
      # Encourages the use of `raise_resource_not_available_error!` method
      # instead of `raise Gitlab::Graphql::Errors::ResourceNotAvailable`.
      #
      # @example
      #
      #   # bad
      #   raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'message'
      #
      #   # good
      #   raise_resource_not_available_error! 'message'
      class ResourceNotAvailableError < Base
        extend NodePatternHelper
        extend AutoCorrector

        MSG = 'Prefer using `raise_resource_not_available_error!` instead.'

        EXCEPTION = 'Gitlab::Graphql::Errors::ResourceNotAvailable'

        RESTRICT_ON_SEND = %i[raise].freeze

        def_node_matcher :error, const_pattern(EXCEPTION)

        def_node_matcher :raise_error, <<~PATTERN
          (send nil? :raise #error $...)
        PATTERN

        def on_send(node)
          raise_error(node) do |args|
            add_offense(node) do |corrector|
              replacement = +'raise_resource_not_available_error!'
              replacement << " #{args.map(&:source).join(', ')}" if args.any?

              corrector.replace(node, replacement)
            end
          end
        end
      end
    end
  end
end
