# frozen_string_literal: true

module Projects
  class EnableDeployKeyService < BaseService
    def execute
      key_id = params[:key_id] || params[:id]
      key = find_accessible_key(key_id)

      return unless key

      unless project.deploy_keys.include?(key)
        project.deploy_keys << key
      end

      key
    end

    private

    def find_accessible_key(key_id)
      if current_user.admin?
        DeployKey.find_by_id(key_id)
      else
        current_user.accessible_deploy_keys.find_by_id(key_id)
      end
    end
  end
end

Projects::EnableDeployKeyService.prepend_mod_with('Projects::EnableDeployKeyService')
