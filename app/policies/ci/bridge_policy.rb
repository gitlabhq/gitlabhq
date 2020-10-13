# frozen_string_literal: true

module Ci
  class BridgePolicy < CommitStatusPolicy
    condition(:can_update_downstream_branch) do
      ::Gitlab::UserAccess.new(@user, container: @subject.downstream_project)
                          .can_update_branch?(@subject.target_revision_ref)
    end

    rule { can_update_downstream_branch }.enable :play_job
  end
end
