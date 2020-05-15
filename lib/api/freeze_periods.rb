# frozen_string_literal: true

module API
  class FreezePeriods < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get project freeze periods' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
      end
      params do
        use :pagination
      end

      get ":id/freeze_periods" do
        authorize! :read_freeze_period, user_project

        freeze_periods = ::FreezePeriodsFinder.new(user_project, current_user).execute

        present paginate(freeze_periods), with: Entities::FreezePeriod, current_user: current_user
      end

      desc 'Get a single freeze period' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
      end
      params do
        requires :freeze_period_id, type: Integer, desc: 'The ID of a project freeze period'
      end
      get ":id/freeze_periods/:freeze_period_id" do
        authorize! :read_freeze_period, user_project

        present freeze_period, with: Entities::FreezePeriod, current_user: current_user
      end

      desc 'Create a new freeze period' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
      end
      params do
        requires :freeze_start, type: String, desc: 'Freeze Period start'
        requires :freeze_end, type: String, desc: 'Freeze Period end'
        optional :cron_timezone, type: String, desc: 'Timezone'
      end
      post ':id/freeze_periods' do
        authorize! :create_freeze_period, user_project

        freeze_period_params = declared(params, include_parent_namespaces: false)

        freeze_period = user_project.freeze_periods.create(freeze_period_params)

        if freeze_period.persisted?
          present freeze_period, with: Entities::FreezePeriod
        else
          render_validation_error!(freeze_period)
        end
      end

      desc 'Update a freeze period' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
      end
      params do
        optional :freeze_start, type: String, desc: 'Freeze Period start'
        optional :freeze_end, type: String, desc: 'Freeze Period end'
        optional :cron_timezone, type: String, desc: 'Freeze Period Timezone'
      end
      put ':id/freeze_periods/:freeze_period_id' do
        authorize! :update_freeze_period, user_project

        freeze_period_params = declared(params, include_parent_namespaces: false, include_missing: false)

        if freeze_period.update(freeze_period_params)
          present freeze_period, with: Entities::FreezePeriod
        else
          render_validation_error!(freeze_period)
        end
      end

      desc 'Delete a freeze period' do
        detail 'This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
      end
      params do
        requires :freeze_period_id, type: Integer, desc: 'Freeze Period ID'
      end
      delete ':id/freeze_periods/:freeze_period_id' do
        authorize! :destroy_freeze_period, user_project

        destroy_conditionally!(freeze_period)
      end
    end

    helpers do
      def freeze_period
        @freeze_period ||= user_project.freeze_periods.find(params[:freeze_period_id])
      end
    end
  end
end
