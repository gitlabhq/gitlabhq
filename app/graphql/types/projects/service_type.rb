# frozen_string_literal: true

module Types
  module Projects
    module ServiceType
      include Types::BaseInterface
      graphql_name 'Service'

      # TODO: Add all the fields that we want to expose for the project services integrations
      # https://gitlab.com/gitlab-org/gitlab/-/issues/213088
      field :type, GraphQL::Types::String, null: true,
            description: 'Class name of the service.'
      field :active, GraphQL::Types::Boolean, null: true,
            description: 'Indicates if the service is active.'

      definition_methods do
        def resolve_type(object, context)
          if object.is_a?(::Integrations::Jira)
            Types::Projects::Services::JiraServiceType
          else
            Types::Projects::Services::BaseServiceType
          end
        end
      end

      orphan_types Types::Projects::Services::BaseServiceType, Types::Projects::Services::JiraServiceType
    end
  end
end
