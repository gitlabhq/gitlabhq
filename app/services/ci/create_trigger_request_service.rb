# This class is deprecated because we're closing trigger_requests.
# New class is PipelineTriggerService (app/services/ci/pipeline_trigger_service.rb).
module Ci
  class CreateTriggerRequestService
    def execute(project, trigger, ref, variables = nil)
      trigger_request = trigger.trigger_requests.create(variables: variables)

      pipeline = Ci::CreatePipelineService.new(project, trigger.owner, ref: ref)
        .execute(:trigger, ignore_skip_ci: true, trigger_request: trigger_request)

      trigger_request if pipeline.persisted?
    end
  end
end
