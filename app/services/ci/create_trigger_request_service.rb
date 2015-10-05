module Ci
  class CreateTriggerRequestService
    def execute(project, trigger, ref, variables = nil)
      return unless project.gl_project
      return unless project.gl_project.repository

      # check if ref is tag
      target = project.gl_project.repository.rev_parse_target(ref)
      sha = target.oid
      tag = target.is_a?(Rugged::Tag) || target.is_a?(Rugged::Tag::Annotation)

      ci_commit = project.gl_project.ensure_ci_commit(sha)
      trigger_request = trigger.trigger_requests.create!(
        variables: variables
      )

      if ci_commit.create_builds(ref, tag, nil, trigger_request)
        trigger_request
      end
    rescue Rugged::OdbError
      nil
    end
  end
end
