# frozen_string_literal: true

module API
  module Entities
    class PlanLimit < Grape::Entity
      expose :ci_pipeline_size, documentation: { type: 'integer', example: 0 }
      expose :ci_active_jobs, documentation: { type: 'integer', example: 0 }
      expose :ci_project_subscriptions, documentation: { type: 'integer', example: 2 }
      expose :ci_pipeline_schedules, documentation: { type: 'integer', example: 10 }
      expose :ci_needs_size_limit, documentation: { type: 'integer', example: 50 }
      expose :ci_registered_group_runners, documentation: { type: 'integer', example: 1000 }
      expose :ci_registered_project_runners, documentation: { type: 'integer', example: 1000 }
      expose :conan_max_file_size, documentation: { type: 'integer', example: 3221225472 }
      expose :generic_packages_max_file_size, documentation: { type: 'integer', example: 5368709120 }
      expose :helm_max_file_size, documentation: { type: 'integer', example: 5242880 }
      expose :maven_max_file_size, documentation: { type: 'integer', example: 3221225472 }
      expose :npm_max_file_size, documentation: { type: 'integer', example: 524288000 }
      expose :nuget_max_file_size, documentation: { type: 'integer', example: 524288000 }
      expose :pipeline_hierarchy_size, documentation: { type: 'integer', example: 1000 }
      expose :pypi_max_file_size, documentation: { type: 'integer', example: 3221225472 }
      expose :terraform_module_max_file_size, documentation: { type: 'integer', example: 1073741824 }
      expose :storage_size_limit, documentation: { type: 'integer', example: 15000 }
    end
  end
end
