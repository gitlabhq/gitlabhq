class IssuePolicy < IssuablePolicy
  def issue
    @subject
  end

  def rules
    super

    if @subject.confidential? && !can_read_confidential?
      cannot! :read_issue
      cannot! :update_issue
      cannot! :admin_issue
    end
  end

  private

  def can_read_confidential?
    return false unless @user

    IssueCollection.new([@subject]).visible_to(@user).any?
  end
end
