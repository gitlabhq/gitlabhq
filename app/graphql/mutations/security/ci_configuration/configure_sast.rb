# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureSast < BaseMutation
        include FindsProject

        graphql_name 'ConfigureSast'

        argument :project_path, GraphQL::ID_TYPE,
          required: true,
          description: 'Full path of the project.'

        argument :configuration, ::Types::CiConfiguration::Sast::InputType,
          required: true,
          description: 'SAST CI configuration for the project.'

        field :status, GraphQL::STRING_TYPE, null: false,
          description: 'Status of creating the commit for the supplied SAST CI configuration.'

        field :success_path, GraphQL::STRING_TYPE, null: true,
          description: 'Redirect path to use when the response is successful.'

        authorize :push_code

        def resolve(project_path:, configuration:)
          project = authorized_find!(project_path)

          result = ::Security::CiConfiguration::SastCreateService.new(project, current_user, configuration).execute
          prepare_response(result)
        end

        private

        def prepare_response(result)
          {
            status: result[:status],
            success_path: result[:success_path],
            errors: Array(result[:errors])
          }
        end
      end
    end
  end
end
