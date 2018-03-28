module Ci
  class PipelineTriggerService < BaseService
    include Gitlab::Utils::StrongMemoize

    def execute
      if trigger_from_token
        create_pipeline_from_trigger(trigger_from_token)
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

    def variables
      params[:variables].to_h.map do |key, value|
        { key: key, value: value }
      end
    end
  end
end
