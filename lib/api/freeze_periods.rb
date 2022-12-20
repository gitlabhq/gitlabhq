# frozen_string_literal: true

module API
  class FreezePeriods < ::API::Base
    include PaginationParams

    freeze_periods_tags = %w[freeze_periods]

    before { authenticate! }

    feature_category :continuous_delivery
    urgency :low

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'List freeze periods' do
        detail 'Paginated list of Freeze Periods, sorted by created_at in ascending order. ' \
               'This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        is_array true
        tags freeze_periods_tags
      end
      params do
        use :pagination
      end

      get ":id/freeze_periods" do
        authorize! :read_freeze_period, user_project

        freeze_periods = ::Ci::FreezePeriodsFinder.new(user_project, current_user).execute

        present paginate(freeze_periods), with: Entities::FreezePeriod, current_user: current_user
      end

      desc 'Get a freeze period' do
        detail 'Get a freeze period for the given `freeze_period_id`. This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 404, message: 'Not found' }
        ]
        tags freeze_periods_tags
      end
      params do
        requires :freeze_period_id, type: Integer, desc: 'The ID of the freeze period'
      end
      get ":id/freeze_periods/:freeze_period_id" do
        authorize! :read_freeze_period, user_project

        present freeze_period, with: Entities::FreezePeriod, current_user: current_user
      end

      desc 'Create a freeze period' do
        detail 'Creates a freeze period. This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' }
        ]
        tags freeze_periods_tags
      end
      params do
        requires :freeze_start, type: String, desc: 'Start of the freeze period in cron format.'
        requires :freeze_end, type: String, desc: 'End of the freeze period in cron format'
        optional :cron_timezone,
          type: String,
          desc: 'The time zone for the cron fields, defaults to UTC if not provided'
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
        detail 'Updates a freeze period for the given `freeze_period_id`. This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
        failure [
          { code: 400, message: 'Bad request' },
          { code: 401, message: 'Unauthorized' }
        ]
        tags freeze_periods_tags
      end
      params do
        optional :freeze_start, type: String, desc: 'Start of the freeze period in cron format'
        optional :freeze_end, type: String, desc: 'End of the freeze period in cron format'
        optional :cron_timezone, type: String, desc: 'The time zone for the cron fields'
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
        detail 'Deletes a freeze period for the given `freeze_period_id`. This feature was introduced in GitLab 13.0.'
        success Entities::FreezePeriod
        failure [
          { code: 401, message: 'Unauthorized' }
        ]
        tags freeze_periods_tags
      end
      params do
        requires :freeze_period_id, type: Integer, desc: 'The ID of the freeze period'
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
