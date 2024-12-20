# frozen_string_literal: true

module API
  module Admin
    class PlanLimits < ::API::Base
      before { authenticated_as_admin! }

      PLAN_LIMITS_TAGS = %w[plan_limits].freeze

      feature_category :not_owned # rubocop:todo Gitlab/AvoidFeatureCategoryNotOwned

      helpers do
        def current_plan(name)
          plan = ::Admin::PlansFinder.new({ name: name }).execute

          not_found!('Plan') unless plan
          plan
        end
      end

      desc 'Get current plan limits' do
        detail 'List the current limits of a plan on the GitLab instance.'
        success Entities::PlanLimit
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        tags PLAN_LIMITS_TAGS
      end
      params do
        optional :plan_name, type: String, values: Plan.all_plans, default: Plan::DEFAULT,
          desc: 'Name of the plan to get the limits from. Default: default.'
      end
      get "application/plan_limits" do
        params = declared_params(include_missing: false)
        plan = current_plan(params.delete(:plan_name))

        present plan.actual_limits, with: Entities::PlanLimit
      end

      desc 'Change plan limits' do
        detail 'Modify the limits of a plan on the GitLab instance.'
        success Entities::PlanLimit
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' }
        ]
        tags PLAN_LIMITS_TAGS
      end
      params do
        requires :plan_name, type: String, values: Plan.all_plans, desc: 'Name of the plan to update'

        optional :ci_instance_level_variables, type: Integer,
          desc: 'Maximum number of Instance-level CI/CD variables that can be defined'
        optional :ci_pipeline_size, type: Integer, desc: 'Maximum number of jobs in a single pipeline'
        optional :ci_active_jobs, type: Integer, desc: 'Total number of jobs in currently active pipelines'
        optional :ci_project_subscriptions, type: Integer,
          desc: 'Maximum number of pipeline subscriptions to and from a project'
        optional :ci_pipeline_schedules, type: Integer, desc: 'Maximum number of pipeline schedules'
        optional :ci_needs_size_limit, type: Integer, desc: 'Maximum number of needs dependencies that a job can have'
        optional :ci_registered_group_runners, type: Integer,
          desc: 'Maximum number of runners created or active in a group during the past seven days'
        optional :ci_registered_project_runners, type: Integer,
          desc: 'Maximum number of runners created or active in a project during the past seven days'
        optional :conan_max_file_size, type: Integer, desc: 'Maximum Conan package file size in bytes'
        optional :dotenv_size, type: Integer, desc: 'Maximum size of a dotenv artifact in bytes'
        optional :dotenv_variables, type: Integer, desc: 'Maximum number of variables in a dotenv artifact'
        optional :enforcement_limit, type: Integer,
          desc: 'Maximum storage size for the root namespace enforcement in MiB'
        optional :generic_packages_max_file_size, type: Integer, desc: 'Maximum generic package file size in bytes'
        optional :helm_max_file_size, type: Integer, desc: 'Maximum Helm chart file size in bytes'
        optional :maven_max_file_size, type: Integer, desc: 'Maximum Maven package file size in bytes'
        optional :notification_limit, type: Integer,
          desc: 'Maximum storage size for the root namespace notifications in MiB'
        optional :npm_max_file_size, type: Integer, desc: 'Maximum NPM package file size in bytes'
        optional :nuget_max_file_size, type: Integer, desc: 'Maximum NuGet package file size in bytes'
        optional :pypi_max_file_size, type: Integer, desc: 'Maximum PyPI package file size in bytes'
        optional :terraform_module_max_file_size, type: Integer,
          desc: 'Maximum Terraform Module package file size in bytes'
        optional :storage_size_limit, type: Integer, desc: 'Maximum storage size for the root namespace in MiB'
        optional :pipeline_hierarchy_size, type: Integer,
          desc: "Maximum number of downstream pipelines in a pipeline's hierarchy tree"
      end
      put "application/plan_limits" do
        params = declared_params(include_missing: false)
        plan = current_plan(params.delete(:plan_name))

        result = ::Admin::PlanLimits::UpdateService.new(params, current_user: current_user, plan: plan).execute

        if result[:status] == :success
          present plan.actual_limits, with: Entities::PlanLimit
        else
          render_validation_error!(plan.actual_limits)
        end
      end
    end
  end
end
