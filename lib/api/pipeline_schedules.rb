module API
  class PipelineSchedules < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
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
        authorize! :read_pipeline_schedule, user_project

        not_found!('PipelineSchedule') unless pipeline_schedule

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
        authorize! :read_pipeline_schedule, user_project

        not_found!('PipelineSchedule') unless pipeline_schedule
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
        authorize! :read_pipeline_schedule, user_project

        not_found!('PipelineSchedule') unless pipeline_schedule
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
        authorize! :read_pipeline_schedule, user_project

        not_found!('PipelineSchedule') unless pipeline_schedule
        authorize! :admin_pipeline_schedule, pipeline_schedule

        status :accepted
        present pipeline_schedule.destroy, with: Entities::PipelineScheduleDetails
      end
    end

    helpers do
      def pipeline_schedule
        @pipeline_schedule ||=
          user_project.pipeline_schedules
                      .preload(:owner, :last_pipeline)
                      .find_by(id: params.delete(:pipeline_schedule_id))
      end
    end
  end
end
