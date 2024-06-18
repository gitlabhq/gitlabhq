# frozen_string_literal: true

module API
  module Entities
    class PlanLimit < Grape::Entity
      expose :ci_instance_level_variables, documentation: { type: 'integer', example: 25 }
      expose :ci_pipeline_size, documentation: { type: 'integer', example: 0 }
      expose :ci_active_jobs, documentation: { type: 'integer', example: 0 }
      expose :ci_project_subscriptions, documentation: { type: 'integer', example: 2 }
      expose :ci_pipeline_schedules, documentation: { type: 'integer', example: 10 }
      expose :ci_needs_size_limit, documentation: { type: 'integer', example: 50 }
      expose :ci_registered_group_runners, documentation: { type: 'integer', example: 1000 }
      expose :ci_registered_project_runners, documentation: { type: 'integer', example: 1000 }
      expose :conan_max_file_size, documentation: { type: 'integer', example: 3221225472 }
      expose :dotenv_variables, documentation: { type: 'integer', example: 20 }
      expose :dotenv_size, documentation: { type: 'integer', example: 5120 }
      expose :enforcement_limit, documentation: { type: 'integer', example: 15000 }
      expose :generic_packages_max_file_size, documentation: { type: 'integer', example: 5368709120 }
      expose :helm_max_file_size, documentation: { type: 'integer', example: 5242880 }
      expose :limits_history, documentation: {
        type: 'object',
        example: '{"enforcement_limit"=>[{"timestamp"=>1686909124, "user_id"=>1, "username"=>"x", "value"=>5}],
                   "notification_limit"=>[{"timestamp"=>1686909124, "user_id"=>2, "username"=>"y", "value"=>7}]}'
      }
      expose :maven_max_file_size, documentation: { type: 'integer', example: 3221225472 }
      expose :notification_limit, documentation: { type: 'integer', example: 15000 }
      expose :npm_max_file_size, documentation: { type: 'integer', example: 524288000 }
      expose :nuget_max_file_size, documentation: { type: 'integer', example: 524288000 }
      expose :pipeline_hierarchy_size, documentation: { type: 'integer', example: 1000 }
      expose :pypi_max_file_size, documentation: { type: 'integer', example: 3221225472 }
      expose :terraform_module_max_file_size, documentation: { type: 'integer', example: 1073741824 }
      expose :storage_size_limit, documentation: { type: 'integer', example: 15000 }
    end
  end
end
