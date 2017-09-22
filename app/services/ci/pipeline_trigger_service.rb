module Ci
  class PipelineTriggerService < BaseService
    def execute
      if trigger_from_token
        create_pipeline_from_trigger(trigger_from_token)
      elsif job_from_token
        create_pipeline_from_job(job_from_token)
      end
    end

    private

    def create_pipeline_from_trigger(trigger)
      # this check is to not leak the presence of the project if user cannot read it
      return unless trigger.project == project

      pipeline = Ci::CreatePipelineService.new(project, trigger.owner, ref: params[:ref])
        .execute(:trigger, ignore_skip_ci: true) do |pipeline|
          pipeline.trigger_requests.create!(trigger: trigger)
          create_pipeline_variables!(pipeline)
        end

      if pipeline.persisted?
        success(pipeline: pipeline)
      else
        error(pipeline.errors.messages, 400)
      end
    end

    def create_pipeline_from_job(job)
      # this check is to not leak the presence of the project if user cannot read it
      return unless can?(job.user, :read_project, project)

      return error("400 Job has to be running", 400) unless job.running?

      pipeline = Ci::CreatePipelineService.new(project, job.user, ref: params[:ref])
        .execute(:pipeline, ignore_skip_ci: true) do |pipeline|
          job.sourced_pipelines.create!(
            source_pipeline: job.pipeline,
            source_project: job.project,
            pipeline: pipeline,
            project: project)

          create_pipeline_variables!(pipeline)
        end

      if pipeline.persisted?
        success(pipeline: pipeline)
      else
        error(pipeline.errors.messages, 400)
      end
    end

    def trigger_from_token
      return @trigger if defined?(@trigger)

      @trigger = Ci::Trigger.find_by_token(params[:token].to_s)
    end

    def job_from_token
      return @job if defined?(@job)

      @job = Ci::Build.find_by_token(params[:token].to_s)
    end

    def create_pipeline_variables!(pipeline)
      return unless params[:variables]

      variables = params[:variables].map do |key, value|
        { key: key, value: value }
      end

      pipeline.variables.create!(variables)
    end
  end
end
