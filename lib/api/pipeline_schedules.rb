module API
  class PipelineSchedules < Grape::API
    include PaginationParams

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: { id: %r{[^/]+} } do
      desc 'Get pipeline_schedules list' do
        success Entities::PipelineSchedule
      end
      params do
        use :pagination
      end
      get ':id/pipeline_schedules' do
        authenticate!
        authorize! :read_pipeline_schedule, user_project

        pipeline_schedules = user_project.pipeline_schedules

        present paginate(pipeline_schedules), with: Entities::PipelineSchedule
      end

      desc 'Get specific pipeline_schedule of a project' do
        success Entities::PipelineSchedule
      end
      params do
        requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline_schedule ID'
      end
      get ':id/pipeline_schedules/:pipeline_schedule_id' do
        authenticate!
        authorize! :read_pipeline_schedule, user_project

        pipeline_schedule = user_project.pipeline_schedules.find(params.delete(:pipeline_schedule_id))
        return not_found!('PipelineSchedule') unless pipeline_schedule

        present pipeline_schedule, with: Entities::PipelineSchedule
      end

      desc 'Create a pipeline_schedule' do
        success Entities::PipelineSchedule
      end
      params do
        requires :description, type: String, desc: 'The pipeline_schedule description'
        requires :ref, type: String, desc: 'The pipeline_schedule ref'
        requires :cron, type: String, desc: 'The pipeline_schedule cron'
        requires :cron_timezone, type: String, desc: 'The pipeline_schedule cron_timezone'
        requires :active, type: Boolean, desc: 'The pipeline_schedule active'
      end
      post ':id/pipeline_schedules' do
        authenticate!
        authorize! :create_pipeline_schedule, user_project

        pipeline_schedule = user_project.pipeline_schedules.create(
          declared_params(include_missing: false).merge(owner: current_user))

        if pipeline_schedule.valid?
          present pipeline_schedule, with: Entities::PipelineSchedule
        else
          render_validation_error!(pipeline_schedule)
        end
      end

      desc 'Update a pipeline_schedule' do
        success Entities::PipelineSchedule
      end
      params do
        requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline_schedule ID'
        optional :description, type: String, desc: 'The pipeline_schedule description'
        optional :ref, type: String, desc: 'The pipeline_schedule ref'
        optional :cron, type: String, desc: 'The pipeline_schedule cron'
        optional :cron_timezone, type: String, desc: 'The pipeline_schedule cron_timezone'
        optional :active, type: Boolean, desc: 'The pipeline_schedule active'
      end
      put ':id/pipeline_schedules/:pipeline_schedule_id' do
        authenticate!
        authorize! :create_pipeline_schedule, user_project

        pipeline_schedule = user_project.pipeline_schedules.find(params.delete(:pipeline_schedule_id))
        return not_found!('PipelineSchedule') unless pipeline_schedule

        if pipeline_schedule.update(declared_params(include_missing: false))
          present pipeline_schedule, with: Entities::PipelineSchedule
        else
          render_validation_error!(pipeline_schedule)
        end
      end

      desc 'Take ownership of pipeline_schedule' do
        success Entities::PipelineSchedule
      end
      params do
        requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline_schedule ID'
      end
      post ':id/pipeline_schedules/:pipeline_schedule_id/take_ownership' do
        authenticate!
        authorize! :create_pipeline_schedule, user_project

        pipeline_schedule = user_project.pipeline_schedules.find(params.delete(:pipeline_schedule_id))
        return not_found!('PipelineSchedule') unless pipeline_schedule

        if pipeline_schedule.update(owner: current_user)
          status :ok
          present pipeline_schedule, with: Entities::PipelineSchedule
        else
          render_validation_error!(pipeline_schedule)
        end
      end

      desc 'Delete a pipeline_schedule' do
        success Entities::PipelineSchedule
      end
      params do
        requires :pipeline_schedule_id, type: Integer,  desc: 'The pipeline_schedule ID'
      end
      delete ':id/pipeline_schedules/:pipeline_schedule_id' do
        authenticate!
        authorize! :admin_pipeline_schedule, user_project

        pipeline_schedule = user_project.pipeline_schedules.find(params.delete(:pipeline_schedule_id))
        return not_found!('PipelineSchedule') unless pipeline_schedule

        present pipeline_schedule.destroy, with: Entities::PipelineSchedule
      end
    end
  end
end
