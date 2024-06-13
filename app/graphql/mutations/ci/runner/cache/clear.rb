# frozen_string_literal: true

module Mutations
  module Ci
    module Runner
      module Cache
        class Clear < BaseMutation
          graphql_name 'RunnerCacheClear'

          authorize :admin_runner

          argument :project_id, ::Types::GlobalIDType[Project],
            required: true,
            description: 'Global ID of the project that will have its runner cache cleared.'

          def resolve(project_id:)
            project = authorized_find!(id: project_id)

            ResetProjectCacheService.new(project, current_user).execute
          end
        end
      end
    end
  end
end
