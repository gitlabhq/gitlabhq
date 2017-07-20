module Ci
  module CreateTriggerRequestService
    Result = Struct.new(:trigger_request, :pipeline)

    def self.execute(project, trigger, ref, variables = nil)
      trigger_request = trigger.trigger_requests.create(variables: variables)

      pipeline = Ci::CreatePipelineService.new(project, trigger.owner, ref: ref)
        .execute(:trigger, ignore_skip_ci: true, trigger_request: trigger_request)

      Result.new(trigger_request, pipeline)
    end
  end
end
