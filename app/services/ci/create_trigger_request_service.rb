# This class is deprecated because we're closing Ci::TriggerRequest.
# New class is PipelineTriggerService (app/services/ci/pipeline_trigger_service.rb)
# which is integrated with Ci::PipelineVariable instaed of Ci::TriggerRequest.
# We remove this class after we removed v1 and v3 API. This class is still being
# referred by such legacy code.
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
