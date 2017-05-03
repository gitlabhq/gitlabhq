class IssuablePolicy < BasePolicy
  def action_name
    @subject.class.name.underscore
  end

  def rules
    if @user && @subject.assignee_or_author?(@user)
      can! :"read_#{action_name}"
      can! :"update_#{action_name}"
    end

    delegate! @subject.project
  end
end
