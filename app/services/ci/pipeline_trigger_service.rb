module Ci
  class PipelineTriggerService < BaseService
    include Gitlab::Utils::StrongMemoize

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
          pipeline.trigger_requests.build(trigger: trigger)
          pipeline.variables.build(variables)
<<<<<<< HEAD
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
          source = job.sourced_pipelines.build(
            source_pipeline: job.pipeline,
            source_project: job.project,
            pipeline: pipeline,
            project: project)

          pipeline.source_pipeline = source
          pipeline.variables.build(variables)
=======
>>>>>>> upstream/master
        end

      if pipeline.persisted?
        success(pipeline: pipeline)
      else
        error(pipeline.errors.messages, 400)
      end
    end

    def trigger_from_token
      strong_memoize(:trigger) do
        Ci::Trigger.find_by_token(params[:token].to_s)
      end
    end

<<<<<<< HEAD
    def job_from_token
      strong_memoize(:job) do
        Ci::Build.find_by_token(params[:token].to_s)
      end
    end

=======
>>>>>>> upstream/master
    def variables
      params[:variables].to_h.map do |key, value|
        { key: key, value: value }
      end
    end
  end
end
