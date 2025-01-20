# frozen_string_literal: true

module API
  module Ci
    class PipelineSchedules < ::API::Base
      include PaginationParams

      before { authenticate! }

      feature_category :continuous_integration
      urgency :low

      params do
        requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project',
          documentation: { example: 18 }
      end
      resource :projects, requirements: ::API::API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        desc 'Get all pipeline schedules' do
          success code: 200, model: Entities::Ci::PipelineSchedule
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
        end
        params do
          use :pagination
          optional :scope, type: String, values: %w[active inactive],
            desc: 'The scope of pipeline schedules',
            documentation: { example: 'active' }
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
          success code: 200, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id', documentation: { example: 13 }
        end
        get ':id/pipeline_schedules/:pipeline_schedule_id' do
          present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails, user: current_user
        end

        desc 'Get all pipelines triggered from a pipeline schedule' do
          success code: 200, model: Entities::Ci::PipelineBasic
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          is_array true
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule ID', documentation: { example: 13 }
        end
        get ':id/pipeline_schedules/:pipeline_schedule_id/pipelines' do
          present paginate(pipeline_schedule.pipelines), with: Entities::Ci::PipelineBasic
        end

        desc 'Create a new pipeline schedule' do
          success code: 201, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :description, type: String, desc: 'The description of pipeline schedule', documentation: { example: 'Test schedule pipeline' }
          requires :ref, type: String, desc: 'The branch/tag name will be triggered', allow_blank: false, documentation: { example: 'develop' }
          requires :cron, type: String, desc: 'The cron', documentation: { example: '* * * * *' }
          optional :cron_timezone, type: String, default: 'UTC', desc: 'The timezone', documentation: { example: 'Asia/Tokyo' }
          optional :active, type: Boolean, default: true, desc: 'The activation of pipeline schedule', documentation: { example: true }
        end
        post ':id/pipeline_schedules' do
          authorize! :create_pipeline_schedule, user_project

          response = ::Ci::PipelineSchedules::CreateService
            .new(user_project, current_user, declared_params(include_missing: false))
            .execute

          pipeline_schedule = response.payload

          if response.success?
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Edit a pipeline schedule' do
          success code: 200, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline schedule id', documentation: { example: 13 }
          optional :description, type: String, desc: 'The description of pipeline schedule', documentation: { example: 'Test schedule pipeline' }
          optional :ref, type: String, desc: 'The branch/tag name will be triggered', documentation: { example: 'develop' }
          optional :cron, type: String, desc: 'The cron', documentation: { example: '* * * * *' }
          optional :cron_timezone, type: String, desc: 'The timezone', documentation: { example: 'Asia/Tokyo' }
          optional :active, type: Boolean, desc: 'The activation of pipeline schedule', documentation: { example: true }
        end
        put ':id/pipeline_schedules/:pipeline_schedule_id' do
          authorize! :update_pipeline_schedule, pipeline_schedule

          response = ::Ci::PipelineSchedules::UpdateService
            .new(pipeline_schedule, current_user, declared_params(include_missing: false))
            .execute

          if response.success?
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Take ownership of a pipeline schedule' do
          success code: 201, model: Entities::Ci::PipelineScheduleDetails
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id', documentation: { example: 13 }
        end
        post ':id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
          authorize! :admin_pipeline_schedule, pipeline_schedule

          if pipeline_schedule.owned_by?(current_user)
            status(:ok) # Set response code to 200 if schedule is already owned by current user
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          elsif pipeline_schedule.own!(current_user)
            present pipeline_schedule, with: Entities::Ci::PipelineScheduleDetails
          else
            render_validation_error!(pipeline_schedule)
          end
        end

        desc 'Delete a pipeline schedule' do
          success code: 204
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' },
            { code: 412, message: 'Precondition Failed' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id', documentation: { example: 13 }
        end
        delete ':id/pipeline_schedules/:pipeline_schedule_id' do
          authorize! :admin_pipeline_schedule, pipeline_schedule

          destroy_conditionally!(pipeline_schedule)
        end

        desc 'Play a scheduled pipeline immediately' do
          detail 'This feature was added in GitLab 12.8'
          success code: 201
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id', documentation: { example: 13 }
        end
        post ':id/pipeline_schedules/:pipeline_schedule_id/play' do
          authorize! :play_pipeline_schedule, pipeline_schedule

          job_id = ::Ci::PipelineSchedules::PlayService
          .new(pipeline_schedule.project, current_user)
          .execute(pipeline_schedule)

          if job_id
            created!
          else
            render_api_error!('Unable to schedule pipeline run immediately', 500)
          end
        end

        desc 'Create a new pipeline schedule variable' do
          success code: 201, model: Entities::Ci::Variable
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id', documentation: { example: 13 }
          requires :key, type: String, desc: 'The key of the variable', documentation: { example: 'NEW_VARIABLE' }
          requires :value, type: String, desc: 'The value of the variable', documentation: { example: 'new value' }
          optional :variable_type, type: String, values: ::Ci::PipelineScheduleVariable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file. Defaults to env_var',
            documentation: { default: 'env_var' }
        end
        post ':id/pipeline_schedules/:pipeline_schedule_id/variables' do
          authorize! :set_pipeline_variables, user_project
          authorize! :update_pipeline_schedule, pipeline_schedule

          response = ::Ci::PipelineSchedules::VariablesCreateService
            .new(pipeline_schedule, current_user, declared_params(include_missing: false))
            .execute

          variable = response.payload

          if response.success?
            present variable, with: Entities::Ci::Variable
          else
            render_validation_error!(variable)
          end
        end

        desc 'Edit a pipeline schedule variable' do
          success code: 200, model: Entities::Ci::Variable
          failure [
            { code: 400, message: 'Bad request' },
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id', documentation: { example: 13 }
          requires :key, type: String, desc: 'The key of the variable', documentation: { example: 'NEW_VARIABLE' }
          optional :value, type: String, desc: 'The value of the variable', documentation: { example: 'new value' }
          optional :variable_type, type: String, values: ::Ci::PipelineScheduleVariable.variable_types.keys, desc: 'The type of variable, must be one of env_var or file',
            documentation: { default: 'env_var' }
        end
        put ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
          authorize! :set_pipeline_variables, user_project
          authorize! :update_pipeline_schedule, pipeline_schedule

          response = ::Ci::PipelineSchedules::VariablesUpdateService
            .new(pipeline_schedule_variable, current_user, declared_params(include_missing: false))
            .execute

          if response.success?
            present pipeline_schedule_variable, with: Entities::Ci::Variable
          else
            render_validation_error!(pipeline_schedule_variable)
          end
        end

        desc 'Delete a pipeline schedule variable' do
          success code: 202, model: Entities::Ci::Variable
          failure [
            { code: 401, message: 'Unauthorized' },
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id', documentation: { example: 13 }
          requires :key, type: String, desc: 'The key of the variable', documentation: { example: 'NEW_VARIABLE' }
        end
        delete ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
          authorize! :set_pipeline_variables, user_project
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
