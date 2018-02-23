class IssuePolicy < IssuablePolicy
  # This class duplicates the same check of Issue#readable_by? for performance reasons
  # Make sure to sync this class checks with issue.rb to avoid security problems.
  # Check commit 002ad215818450d2cbbc5fa065850a953dc7ada8 for more information.

  desc "User can read confidential issues"
  condition(:can_read_confidential) do
    @user && IssueCollection.new([@subject]).visible_to(@user).any?
  end

  desc "Issue is confidential"
  condition(:confidential, scope: :subject) { @subject.confidential? }

  rule { confidential & ~can_read_confidential }.policy do
    prevent :read_issue
    prevent :read_issue_iid
    prevent :update_issue
    prevent :admin_issue
  end

  rule { can?(:read_issue) | visible_to_user }.enable :read_issue_iid
end
