# frozen_string_literal: true

module Ci
  class BridgePolicy < CommitStatusPolicy
    include Ci::DeployablePolicy

    condition(:can_update_downstream_branch) do
      # `bridge.downstream_project` could be `nil` if the downstream project was removed after the pipeline creation,
      # which raises an error in `UserAccess` class because `container` arg must be present.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/424145 for more information.
      @subject.downstream_project.present? &&
        ::Gitlab::UserAccess.new(@user, container: @subject.downstream_project)
                            .can_update_branch?(@subject.target_revision_ref)
    end

    rule { can_update_downstream_branch }.enable :play_job
  end
end
