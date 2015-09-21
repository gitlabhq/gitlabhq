module Ci
  class CreateTriggerRequestService
    def execute(project, trigger, ref, variables = nil)
      commit = project.commits.where(ref: ref).last
      return unless commit

      trigger_request = trigger.trigger_requests.create!(
        commit: commit,
        variables: variables
      )

      if commit.create_builds(trigger_request)
        trigger_request
      end
    end
  end
end
