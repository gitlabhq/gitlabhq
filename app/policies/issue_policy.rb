class IssuePolicy < IssuablePolicy
  # This class duplicates the same check of Issue#readable_by? for performance reasons
  # Make sure to sync this class checks with issue.rb to avoid security problems.
  # Check commit 002ad215818450d2cbbc5fa065850a953dc7ada8 for more information.

  def issue
    @subject
  end

  def rules
    super

    if @subject.confidential? && !can_read_confidential?
      cannot! :read_issue
      cannot! :admin_issue
      cannot! :update_issue
      cannot! :read_issue
    end
  end

  private

  def can_read_confidential?
    return false unless @user
    return true if @user.admin?
    return true if @subject.author == @user
    return true if @subject.assignee == @user
    return true if @subject.project.team.member?(@user, Gitlab::Access::REPORTER)

    false
  end
end
