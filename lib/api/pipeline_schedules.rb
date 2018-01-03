module API
  class PipelineSchedules < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get all pipeline schedules' do
        success Entities::PipelineSchedule
      end
      params do
        use :pagination
        optional :scope,    type: String, values: %w[active inactive],
                            desc: 'The scope of pipeline schedules'
      end
      get ':id/pipeline_schedules' do
        authorize! :read_pipeline_schedule, user_project

        schedules = PipelineSchedulesFinder.new(user_project).execute(scope: params[:scope])
          .preload([:owner, :last_pipeline])
        present paginate(schedules), with: Entities::PipelineSchedule
      end

      desc 'Get a single pipeline schedule' do
        success Entities::PipelineScheduleDetails
      end
      params do
        requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline schedule id'
      end
      get ':id/pipeline_schedules/:pipeline_schedule_id' do
        present pipeline_schedule, with: Entities::PipelineScheduleDetails
      end

      desc 'Create a new pipeline schedule' do
        success Entities::PipelineScheduleDetails
      end
      params do
        requires :description, type: String, desc: 'The description of pipeline schedule'
        requires :ref, type: String, desc: 'The branch/tag name will be triggered'
        requires :cron, type: String, desc: 'The cron'
        optional :cron_timezone, type: String, default: 'UTC', desc: 'The timezone'
        optional :active, type: Boolean, default: true, desc: 'The activation of pipeline schedule'
      end
      post ':id/pipeline_schedules' do
        authorize! :create_pipeline_schedule, user_project

        pipeline_schedule = Ci::CreatePipelineScheduleService
          .new(user_project, current_user, declared_params(include_missing: false))
          .execute

        if pipeline_schedule.persisted?
          present pipeline_schedule, with: Entities::PipelineScheduleDetails
        else
          render_validation_error!(pipeline_schedule)
        end
      end

      desc 'Edit a pipeline schedule' do
        success Entities::PipelineScheduleDetails
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
          present pipeline_schedule, with: Entities::PipelineScheduleDetails
        else
          render_validation_error!(pipeline_schedule)
        end
      end

      desc 'Take ownership of a pipeline schedule' do
        success Entities::PipelineScheduleDetails
      end
      params do
        requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline schedule id'
      end
      post ':id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
        authorize! :update_pipeline_schedule, pipeline_schedule

        if pipeline_schedule.own!(current_user)
          present pipeline_schedule, with: Entities::PipelineScheduleDetails
        else
          render_validation_error!(pipeline_schedule)
        end
      end

      desc 'Delete a pipeline schedule' do
        success Entities::PipelineScheduleDetails
      end
      params do
        requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline schedule id'
      end
      delete ':id/pipeline_schedules/:pipeline_schedule_id' do
        authorize! :admin_pipeline_schedule, pipeline_schedule

        destroy_conditionally!(pipeline_schedule)
      end

      desc 'Create a new pipeline schedule variable' do
        success Entities::Variable
      end
      params do
        requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
        requires :key, type: String, desc: 'The key of the variable'
        requires :value, type: String, desc: 'The value of the variable'
      end
      post ':id/pipeline_schedules/:pipeline_schedule_id/variables' do
        authorize! :update_pipeline_schedule, pipeline_schedule

        variable_params = declared_params(include_missing: false)
        variable = pipeline_schedule.variables.create(variable_params)
        if variable.persisted?
          present variable, with: Entities::Variable
        else
          render_validation_error!(variable)
        end
      end

      desc 'Edit a pipeline schedule variable' do
        success Entities::Variable
      end
      params do
        requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
        requires :key, type: String, desc: 'The key of the variable'
        optional :value, type: String, desc: 'The value of the variable'
      end
      put ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
        authorize! :update_pipeline_schedule, pipeline_schedule

        if pipeline_schedule_variable.update(declared_params(include_missing: false))
          present pipeline_schedule_variable, with: Entities::Variable
        else
          render_validation_error!(pipeline_schedule_variable)
        end
      end

      desc 'Delete a pipeline schedule variable' do
        success Entities::Variable
      end
      params do
        requires :pipeline_schedule_id, type: Integer, desc: 'The pipeline schedule id'
        requires :key, type: String, desc: 'The key of the variable'
      end
      delete ':id/pipeline_schedules/:pipeline_schedule_id/variables/:key' do
        authorize! :admin_pipeline_schedule, pipeline_schedule

        status :accepted
        present pipeline_schedule_variable.destroy, with: Entities::Variable
      end
    end

    helpers do
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

      def pipeline_schedule_variable
        @pipeline_schedule_variable ||=
          pipeline_schedule.variables.find_by(key: params[:key]).tap do |pipeline_schedule_variable|
            unless pipeline_schedule_variable
              not_found!('Pipeline Schedule Variable')
            end
          end
      end
    end
  end
end
