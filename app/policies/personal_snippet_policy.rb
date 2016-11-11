class PersonalSnippetPolicy < BasePolicy
  def rules
    can! :read_personal_snippet if @subject.public?
    return unless @user

    if @subject.author == @user
      can! :read_personal_snippet
      can! :update_personal_snippet
      can! :admin_personal_snippet
    end

    if @subject.internal? && !@user.external?
      can! :read_personal_snippet
    end
  end
end
