class IssuablePolicy < BasePolicy
  delegate { @subject.project }

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
end
