# frozen_string_literal: true

module Resolvers
  module Integrations
    class ExclusionsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      type Types::Integrations::ExclusionType.connection_type, null: true

      argument :integration_name, Types::Integrations::IntegrationTypeEnum,
        required: true,
        description: 'Type of integration.'

      def resolve(integration_name:)
        authorize!
        Integration.integration_name_to_model(integration_name).with_custom_settings.by_active_flag(false)
      end

      def authorize!
        raise_resource_not_available_error! unless context[:current_user]&.can_admin_all_resources?
      end
    end
  end
end
