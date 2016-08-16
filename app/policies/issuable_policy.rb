class IssuablePolicy < BasePolicy
  def action_name
    @subject.class.name.underscore
  end

  def rules
    if @user && (@subject.author == @user || @subject.assignee == @user)
      can! :"read_#{action_name}"
      can! :"update_#{action_name}"
    end

    delegate! @subject.project
  end
end
