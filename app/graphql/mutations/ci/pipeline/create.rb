# frozen_string_literal: true

module Mutations
  module Ci
    module Pipeline
      class Create < BaseMutation
        graphql_name 'PipelineCreate'

        include FindsProject

        field :pipeline,
          Types::Ci::PipelineType,
          null: true,
          description: 'Pipeline created after mutation.'

        argument :project_path, GraphQL::Types::ID,
          required: true,
          description: 'Full path of the project that is triggering the pipeline.'

        argument :ref, GraphQL::Types::String,
          required: true,
          description: 'Ref on which to run the pipeline.'

        argument :variables, [Types::Ci::VariableInputType],
          required: false,
          description: 'Variables for the pipeline.'

        authorize :create_pipeline

        def resolve(project_path:, **params)
          project = authorized_find!(project_path)

          response = ::Ci::CreatePipelineService
            .new(project, current_user, params)
            .execute(:web, ignore_skip_ci: true, save_on_errors: false)

          if response.success?
            { pipeline: response.payload, errors: [] }
          else
            { pipeline: nil, errors: [response.message] }
          end
        end
      end
    end
  end
end
