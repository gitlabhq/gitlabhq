module Projects
  class EnableDeployKeyService < BaseService
    def execute
      key = accessible_keys.find_by(id: params[:key_id] || params[:id])
      return unless key

      project.deploy_keys << key
      key
    end

    private

    def accessible_keys
      current_user.accessible_deploy_keys
    end
  end
end
