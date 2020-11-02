# frozen_string_literal: true

module API
  module Ci
    class PipelineSchedules < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :continuous_integration

      params do
        requires :id, type: String, desc: 'The ID of a project'
      end
      resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get all pipeline schedules' do
          success Entities::Ci::PipelineSchedule
        end
        params do
          use :pagination
          optional :scope,    type: String, values: %w[active inactive],
                              desc: 'The scope of pipeline schedules'
        end
        # rubocop: disable CodeReuse/ActiveRecord
        get ':id/pipeline_schedules' do
          authorize! :read_pipeline_schedule, user_project

          schedules = ::Ci::PipelineSchedulesFinder.new(user_project).execute(scope: params[:scope])
            .preload([:owner, :last_pipeline])
          present paginate(schedules), with: Entities::Ci::PipelineSchedule
        end
        # rubocop: enable CodeReuse/ActiveRecord

        desc 'Get a single pipeline schedule' do
          success Entities::Ci::PipelineScheduleDetails
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
        end
        get ':id/pipeline_schedules/:pipeline_schedule_id' do
          present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails, user: current_user
        end

        desc 'Create a new pipeline schedule' do
          success Entities::Ci::PipelineScheduleDetails
        end
        params do
          requires :description, type: String, desc: 'The description of pipeline schedule'
          requires :ref, type: String, desc: 'The branch/tag name will be triggered', allow_blank: false
          requires :cron, type: String, desc: 'The cron'
          optional :cron_timezone, type: String, default: 'UTC', desc: 'The timezone'
          optional :active, type: Boolean, default: true, desc: 'The activation of pipeline schedule'
        end
        post ':id/pipeline_schedules' do
          authorize! :create_pipeline_schedule, user_project

          pipeline_schedule = ::Ci::CreatePipelineScheduleService
            .new(user_project, current_user, declared_params(include_missing: false))
            .execute

          if pipeline_schedule.persisted?
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Edit a pipeline schedule' do
          success Entities::Ci::PipelineScheduleDetails
        end
        params do
          requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline schedule id'
          optional :description, type: String, desc: 'The description of pipeline schedule'
          optional :ref, type: String, desc: 'The branch/tag name will be triggered'
          optional :cron, type: String, desc: 'The cron'
          optional :cron_timezone, type: String, desc: 'The timezone'
          optional :active, type: Boolean, desc: 'The activation of pipeline schedule'
        end
        put ':id/pipeline_schedules/:pipeline_schedule_id' do
          authorize! :update_pipeline_schedule, pipeline_schedule

          if pipeline_schedule.update(declared_params(include_missing: false))
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Take ownership of a pipeline schedule' do
          success Entities::Ci::PipelineScheduleDetails
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
        end
        post ':id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
          authorize! :update_pipeline_schedule, pipeline_schedule

          if pipeline_schedule.own!(current_user)
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Delete a pipeline schedule' do
          success Entities::Ci::PipelineScheduleDetails
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
        end
        delete ':id/pipeline_schedules/:pipeline_schedule_id' do
          authorize! :admin_pipeline_schedule, pipeline_schedule

          destroy_conditionally!(pipeline_schedule)
        end

        desc 'Play a scheduled pipeline immediately' do
          detail 'This feature was added in GitLab 12.8'
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
        end
        post ':id/pipeline_schedules/:pipeline_schedule_id/play' do
          authorize! :play_pipeline_schedule, pipeline_schedule

          job_id = RunPipelineScheduleWorker # rubocop:disable CodeReuse/Worker
            .perform_async(pipeline_schedule.id, current_user.id)

          if job_id
            created!
          else
            render_api_error!('Unable to schedule pipeline run immediately', 500)
          end
        end

        desc 'Create a new pipeline schedule variable' do
          success Entities::Ci::Variable
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
          requires :key, type: String, desc: 'The key of the variable'
          requires :value, type: String, desc: 'The value of the variable'
          optional :variable_type, type: String, values: ::Ci::PipelineScheduleVariable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file. Defaults to env_var'
        end
        post ':id/pipeline_schedules/:pipeline_schedule_id/variables' do
          authorize! :update_pipeline_schedule, pipeline_schedule

          variable_params = declared_params(include_missing: false)
          variable = pipeline_schedule.variables.create(variable_params)
          if variable.persisted?
            present variable, with: Entities::Ci::Variable
          else
            render_validation_error!(variable)
          end
        end

        desc 'Edit a pipeline schedule variable' do
          success Entities::Ci::Variable
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
          requires :key, type: String, desc: 'The key of the variable'
          optional :value, type: String, desc: 'The value of the variable'
          optional :variable_type, type: String, values: ::Ci::PipelineScheduleVariable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file'
        end
        put ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
          authorize! :update_pipeline_schedule, pipeline_schedule

          if pipeline_schedule_variable.update(declared_params(include_missing: false))
            present pipeline_schedule_variable, with: Entities::Ci::Variable
          else
            render_validation_error!(pipeline_schedule_variable)
          end
        end

        desc 'Delete a pipeline schedule variable' do
          success Entities::Ci::Variable
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
          requires :key, type: String, desc: 'The key of the variable'
        end
        delete ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
          authorize! :admin_pipeline_schedule, pipeline_schedule

          status :accepted
          present pipeline_schedule_variable.destroy, with: Entities::Ci::Variable
        end
      end

      helpers do
        # rubocop: disable CodeReuse/ActiveRecord
        def pipeline_schedule
          @pipeline_schedule ||=
            user_project
              .pipeline_schedules
              .preload(:owner, :last_pipeline)
              .find_by(id: params.delete(:pipeline_schedule_id)).tap do |pipeline_schedule|
                unless can?(current_user, :read_pipeline_schedule, pipeline_schedule)
                  not_found!('Pipeline Schedule')
                end
              end
        end
        # rubocop: enable CodeReuse/ActiveRecord

        # rubocop: disable CodeReuse/ActiveRecord
        def pipeline_schedule_variable
          @pipeline_schedule_variable ||=
            pipeline_schedule.variables.find_by(key: params[:key]).tap do |pipeline_schedule_variable|
              unless pipeline_schedule_variable
                not_found!('Pipeline Schedule Variable')
              end
            end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
