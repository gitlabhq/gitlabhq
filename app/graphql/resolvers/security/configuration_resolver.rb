# frozen_string_literal: true

module Resolvers
  module Security
    class ConfigurationResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type ::Types::Security::ConfigurationType, null: true
      authorize :read_security_configuration

      argument :project_id, Types::GlobalIDType[::Project],
        required: true,
        description: 'Project to get the security configuration for.'

      def resolve(project_id:)
        project = authorized_find!(id: project_id)

        ::Projects::Security::ConfigurationPresenter.new(project, current_user: current_user).to_h
      end

      private

      def authorized_resource?(project)
        Ability.allowed?(current_user, :read_security_configuration, project)
      end
    end
  end
end
