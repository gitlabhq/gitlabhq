module Ci
  class CreateTriggerRequestService
    def execute(project, trigger, ref, variables = nil)
      commit = project.commit(ref)
      return unless commit

      # check if ref is tag
      tag = project.repository.find_tag(ref).present?

      ci_commit = project.ensure_ci_commit(commit.sha)

      trigger_request = trigger.trigger_requests.create!(
        variables: variables,
        commit: ci_commit,
      )

      if ci_commit.create_builds(ref, tag, nil, trigger_request)
        trigger_request
      end
    end
  end
end
