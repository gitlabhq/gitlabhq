class DeployKeyPolicy < BasePolicy
  def rules
    return unless @user

    can! :update_deploy_key if @user.admin?

    if @subject.private? && @user.project_deploy_keys.exists?(id: @subject.id)
      can! :update_deploy_key
    end
  end
end
