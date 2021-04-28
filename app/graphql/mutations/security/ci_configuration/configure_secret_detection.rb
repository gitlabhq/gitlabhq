# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class ConfigureSecretDetection < BaseMutation
        include FindsProject

        graphql_name 'ConfigureSecretDetection'
        description <<~DESC
          Configure Secret Detection for a project by enabling Secret Detection
          in a new or modified `.gitlab-ci.yml` file in a new branch. The new
          branch and a URL to create a Merge Request are a part of the
          response.
        DESC

        argument :project_path, GraphQL::ID_TYPE,
          required: true,
          description: 'Full path of the project.'

        field :success_path, GraphQL::STRING_TYPE, null: true,
          description: 'Redirect path to use when the response is successful.'

        field :branch, GraphQL::STRING_TYPE, null: true,
          description: 'Branch that has the new/modified `.gitlab-ci.yml` file.'

        authorize :push_code

        def resolve(project_path:)
          project = authorized_find!(project_path)

          result = ::Security::CiConfiguration::SecretDetectionCreateService.new(project, current_user).execute
          prepare_response(result)
        end

        private

        def prepare_response(result)
          {
            branch: result.payload[:branch],
            success_path: result.payload[:success_path],
            errors: result.errors
          }
        end
      end
    end
  end
end
