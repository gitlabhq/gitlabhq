class IssuablePolicy < BasePolicy
  delegate { @subject.project }

  condition(:locked, scope: :subject, score: 0) { @subject.discussion_locked? }

  # We aren't checking `:read_issue` or `:read_merge_request` in this case
  # because it could be possible for a user to see an issuable-iid
  # (`:read_issue_iid` or `:read_merge_request_iid`) but then wouldn't be allowed
  # to read the actual issue after a more expensive `:read_issue` check.
  #
  # `:read_issue` & `:read_issue_iid` could diverge in gitlab-ee.
  condition(:visible_to_user, score: 4) do
    Project.where(id: @subject.project)
      .public_or_visible_to_user(@user)
      .with_feature_available_for_user(@subject, @user)
      .any?
  end

  condition(:is_project_member) { @user && @subject.project && @subject.project.team.member?(@user) }

  desc "User is the assignee or author"
  condition(:assignee_or_author) do
    @user && @subject.assignee_or_author?(@user)
  end

  rule { assignee_or_author }.policy do
    enable :read_issue
    enable :update_issue
    enable :read_merge_request
    enable :update_merge_request
  end

  rule { locked & ~is_project_member }.policy do
    prevent :create_note
    prevent :update_note
    prevent :admin_note
    prevent :resolve_note
    prevent :edit_note
  end
end
