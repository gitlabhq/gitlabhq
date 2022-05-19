# frozen_string_literal: true

module API
  module Entities
    class PlanLimit < Grape::Entity
      expose :ci_pipeline_size
      expose :ci_active_jobs
      expose :ci_active_pipelines
      expose :ci_project_subscriptions
      expose :ci_pipeline_schedules
      expose :ci_needs_size_limit
      expose :ci_registered_group_runners
      expose :ci_registered_project_runners
      expose :conan_max_file_size
      expose :generic_packages_max_file_size
      expose :helm_max_file_size
      expose :maven_max_file_size
      expose :npm_max_file_size
      expose :nuget_max_file_size
      expose :pypi_max_file_size
      expose :terraform_module_max_file_size
      expose :storage_size_limit
    end
  end
end
