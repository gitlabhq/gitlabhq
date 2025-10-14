# frozen_string_literal: true

module Types
  module Namespaces
    class NamespaceSettingsType < BaseObject
      graphql_name 'NamespaceSettings'
      description 'Settings for the namespace'

      authorize :admin_group

      field :step_up_auth_required_oauth_provider,
        GraphQL::Types::String,
        null: true,
        description: 'OAuth provider required for step-up authentication.'

      def step_up_auth_required_oauth_provider
        return unless Feature.enabled?(:omniauth_step_up_auth_for_namespace, object.namespace)

        object.step_up_auth_required_oauth_provider
      end
    end
  end
end
