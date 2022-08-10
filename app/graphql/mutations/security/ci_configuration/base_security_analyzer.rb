# frozen_string_literal: true

module Mutations
  module Security
    module CiConfiguration
      class BaseSecurityAnalyzer < BaseMutation
        include FindsProject

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project.'

        field :success_path, GraphQL::Types::String,
          null: true,
          description: 'Redirect path to use when the response is successful.'

        field :branch, GraphQL::Types::String,
          null: true,
          description: 'Branch that has the new/modified `.gitlab-ci.yml` file.'

        authorize :push_code

        def resolve(project_path:, **args)
          project = authorized_find!(project_path)

          result = configure_analyzer(project, **args)
          prepare_response(result)
        end

        private

        def configure_analyzer(project, **args)
          raise NotImplementedError
        end

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
