class NamespacePolicy < BasePolicy
  def rules
    return unless @user

    if @subject.owner == @user || @user.admin?
      can! :create_projects
      can! :admin_namespace
    end
  end
end
