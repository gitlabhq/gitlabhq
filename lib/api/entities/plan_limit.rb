# frozen_string_literal: true

module API
  module Entities
    class PlanLimit < Grape::Entity
      expose :ci_instance_level_variables, documentation: { type: 'Integer', example: 25 }
      expose :ci_pipeline_size, documentation: { type: 'Integer', example: 0 }
      expose :ci_active_jobs, documentation: { type: 'Integer', example: 0 }
      expose :ci_project_subscriptions, documentation: { type: 'Integer', example: 2 }
      expose :ci_pipeline_schedules, documentation: { type: 'Integer', example: 10 }
      expose :ci_needs_size_limit, documentation: { type: 'Integer', example: 50 }
      expose :ci_registered_group_runners, documentation: { type: 'Integer', example: 1000 }
      expose :ci_registered_project_runners, documentation: { type: 'Integer', example: 1000 }
      expose :conan_max_file_size, documentation: { type: 'Integer', example: 3221225472 }
      expose :dotenv_variables, documentation: { type: 'Integer', example: 20 }
      expose :dotenv_size, documentation: { type: 'Integer', example: 5120 }
      expose :enforcement_limit, documentation: { type: 'Integer', example: 15000 }
      expose :generic_packages_max_file_size, documentation: { type: 'Integer', example: 5368709120 }
      expose :helm_max_file_size, documentation: { type: 'Integer', example: 5242880 }
      expose :limits_history, documentation: {
        type: 'object',
        example: '{"enforcement_limit"=>[{"timestamp"=>1686909124, "user_id"=>1, "username"=>"x", "value"=>5}],
                   "notification_limit"=>[{"timestamp"=>1686909124, "user_id"=>2, "username"=>"y", "value"=>7}]}'
      }
      expose :maven_max_file_size, documentation: { type: 'Integer', example: 3221225472 }
      expose :notification_limit, documentation: { type: 'Integer', example: 15000 }
      expose :npm_max_file_size, documentation: { type: 'Integer', example: 524288000 }
      expose :nuget_max_file_size, documentation: { type: 'Integer', example: 524288000 }
      expose :pipeline_hierarchy_size, documentation: { type: 'Integer', example: 1000 }
      expose :pypi_max_file_size, documentation: { type: 'Integer', example: 3221225472 }
      expose :terraform_module_max_file_size, documentation: { type: 'Integer', example: 1073741824 }
      expose :storage_size_limit, documentation: { type: 'Integer', example: 15000 }
      expose :web_hook_calls, documentation: { type: 'Integer', example: 500 }
      expose :web_hook_calls_low, documentation: { type: 'Integer', example: 500 }
      expose :web_hook_calls_mid, documentation: { type: 'Integer', example: 500 }
    end
  end
end
