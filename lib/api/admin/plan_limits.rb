# frozen_string_literal: true

module API
  module Admin
    class PlanLimits < ::API::Base
      before { authenticated_as_admin! }

      feature_category :not_owned

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

        optional :conan_max_file_size, type: Integer, desc: 'Maximum Conan package file size in bytes'
        optional :generic_packages_max_file_size, type: Integer, desc: 'Maximum generic package file size in bytes'
        optional :maven_max_file_size, type: Integer, desc: 'Maximum Maven package file size in bytes'
        optional :npm_max_file_size, type: Integer, desc: 'Maximum NPM package file size in bytes'
        optional :nuget_max_file_size, type: Integer, desc: 'Maximum NuGet package file size in bytes'
        optional :pypi_max_file_size, type: Integer, desc: 'Maximum PyPI package file size in bytes'
        optional :terraform_module_max_file_size, type: Integer, desc: 'Maximum Terraform Module package file size in bytes'
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
