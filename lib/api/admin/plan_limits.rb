# frozen_string_literal: true

module API
  module Admin
    class PlanLimits < ::API::Base
      before { authenticated_as_admin! }

      feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

      helpers do
        def current_plan(name)
          plan = ::Admin::PlansFinder.new({ name: name }).execute

          not_found!('Plan') unless plan
          plan
        end
      end

      desc 'Get current plan limits' do
        success Entities::PlanLimit
      end
      params do
        optional :plan_name, type: String, values: Plan.all_plans, default: Plan::DEFAULT, desc: 'Name of the plan'
      end
      get "application/plan_limits" do
        params = declared_params(include_missing: false)
        plan = current_plan(params.delete(:plan_name))

        present plan.actual_limits, with: Entities::PlanLimit
      end

      desc 'Modify plan limits' do
        success Entities::PlanLimit
      end
      params do
        requires :plan_name, type: String, values: Plan.all_plans, desc: 'Name of the plan'

        optional :ci_pipeline_size, type: Integer, desc: 'Maximum number of jobs in a single pipeline'
        optional :ci_active_jobs, type: Integer, desc: 'Total number of jobs in currently active pipelines'
        optional :ci_active_pipelines, type: Integer, desc: 'Maximum number of active pipelines per project'
        optional :ci_project_subscriptions, type: Integer, desc: 'Maximum number of pipeline subscriptions to and from a project'
        optional :ci_pipeline_schedules, type: Integer, desc: 'Maximum number of pipeline schedules'
        optional :ci_needs_size_limit, type: Integer, desc: 'Maximum number of DAG dependencies that a job can have'
        optional :ci_registered_group_runners, type: Integer, desc: 'Maximum number of runners registered per group'
        optional :ci_registered_project_runners, type: Integer, desc: 'Maximum number of runners registered per project'
        optional :conan_max_file_size, type: Integer, desc: 'Maximum Conan package file size in bytes'
        optional :generic_packages_max_file_size, type: Integer, desc: 'Maximum generic package file size in bytes'
        optional :helm_max_file_size, type: Integer, desc: 'Maximum Helm chart file size in bytes'
        optional :maven_max_file_size, type: Integer, desc: 'Maximum Maven package file size in bytes'
        optional :npm_max_file_size, type: Integer, desc: 'Maximum NPM package file size in bytes'
        optional :nuget_max_file_size, type: Integer, desc: 'Maximum NuGet package file size in bytes'
        optional :pypi_max_file_size, type: Integer, desc: 'Maximum PyPI package file size in bytes'
        optional :terraform_module_max_file_size, type: Integer, desc: 'Maximum Terraform Module package file size in bytes'
        optional :storage_size_limit, type: Integer, desc: 'Maximum storage size for the root namespace in megabytes'
      end
      put "application/plan_limits" do
        params = declared_params(include_missing: false)
        plan = current_plan(params.delete(:plan_name))

        if plan.actual_limits.update(params)
          present plan.actual_limits, with: Entities::PlanLimit
        else
          render_validation_error!(plan.actual_limits)
        end
      end
    end
  end
end
