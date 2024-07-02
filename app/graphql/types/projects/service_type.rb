# frozen_string_literal: true

module Types
  module Projects
    # TODO: Remove in 17.0, see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/108418
    module ServiceType
      include Types::BaseInterface
      graphql_name 'Service'

      # TODO: Add all the fields that we want to expose for the project services integrations
      # https://gitlab.com/gitlab-org/gitlab/-/issues/213088
      field :type, GraphQL::Types::String, null: true,
        description: 'Class name of the service.'
      field :service_type, ::Types::Projects::ServiceTypeEnum, null: true,
        description: 'Type of the service.', method: :type
      field :active, GraphQL::Types::Boolean, null: true,
        description: 'Indicates if the service is active.'

      def type
        enum = ::Types::Projects::ServiceTypeEnum.coerce_result(object.type, context)
        enum.downcase.camelize
      end

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
