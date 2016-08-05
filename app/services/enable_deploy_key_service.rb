class EnableDeployKeyService < BaseService
  def execute
    key = accessible_keys.find_by(id: params[:key_id] || params[:id])

    project.deploy_keys << key if key
    key
  end

  private

  def accessible_keys
    current_user.accessible_deploy_keys
  end
end
