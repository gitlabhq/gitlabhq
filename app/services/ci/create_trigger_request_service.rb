module Ci
  class CreateTriggerRequestService
    def execute(project, trigger, ref, variables = nil)
      commit = project.commit(ref)
      return unless commit

      trigger_request = trigger.trigger_requests.create!(
        variables: variables,
        pipeline: pipeline,
      )

      pipeline = Ci::CreatePipelineService.new(project, current_user).execute(skip_ci: false, trigger_request: trigger_request)
      if pipeline.persisted?
        trigger_request
      end
    end
  end
end
