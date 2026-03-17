# frozen_string_literal: true

module RuboCop
  module Cop
    module API
      # Checks that route_setting :lifecycle uses valid values.
      #
      # Lifecycle indicates that an endpoint is not yet generally available.
      # Omit route_setting :lifecycle for generally available endpoints.
      #
      # @example
      #
      #   # bad - invalid lifecycle value
      #   route_setting :lifecycle, :alpha
      #
      #   # bad - string instead of symbol
      #   route_setting :lifecycle, 'beta'
      #
      #   # good - endpoint is in beta
      #   route_setting :lifecycle, :beta
      #
      #   # good - endpoint is experimental
      #   route_setting :lifecycle, :experiment
      #
      #   # good - endpoint is generally available (no lifecycle setting needed)
      #   desc 'Get all users' do
      #     detail 'Returns all users'
      #   end
      #   get '/users' do
      #   end
      class RouteSettingLifecycle < RuboCop::Cop::Base
        VALID_VALUES = %i[beta experiment].freeze

        MSG = "Invalid lifecycle value `%s`. Use one of: #{VALID_VALUES.map(&:inspect).join(', ')}. " \
          "Omit route_setting :lifecycle for generally available endpoints. " \
          "See https://docs.gitlab.com/policy/development_stages_support/".freeze

        RESTRICT_ON_SEND = %i[route_setting].freeze

        # @!method lifecycle_setting(node)
        def_node_matcher :lifecycle_setting, <<~PATTERN
          (send nil? :route_setting (sym :lifecycle) $_)
        PATTERN

        def on_send(node)
          lifecycle_setting(node) do |value_node|
            next if valid_value?(value_node)

            add_offense(value_node, message: format(MSG, value_node.source))
          end
        end
        alias_method :on_csend, :on_send

        private

        def valid_value?(node)
          node.sym_type? && VALID_VALUES.include?(node.value)
        end
      end
    end
  end
end
