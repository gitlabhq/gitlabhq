module Ci
  class CreateTriggerRequestService
    def execute(project, trigger, ref, variables = nil)
      commit = project.commit(ref)
      return unless commit

      # check if ref is tag
      tag = project.repository.find_tag(ref).present?

      pipeline = project.pipelines.create(sha: commit.sha, ref: ref, tag: tag)

      trigger_request = trigger.trigger_requests.create!(
        variables: variables,
        pipeline: pipeline,
      )

      if pipeline.create_builds(nil, trigger_request)
        trigger_request
      end
    end
  end
end
