# frozen_string_literal: true

module Projects
  class EnableDeployKeyService < BaseService
    def execute
      key_id = params[:key_id] || params[:id]
      key = find_accessible_key(key_id)

      return unless key
      return unless within_organization_boundary?(key)

      unless project.deploy_keys.include?(key)
        project.deploy_keys << key
      end

      key
    end

    private

    def find_accessible_key(key_id)
      key = DeployKey.find_by_id(key_id)

      key if key && can?(current_user, :enable_deploy_key, key)
    end

    # Comparing ids first avoids loading the project's organization in the common case.
    def within_organization_boundary?(key)
      key.organization_id == project.organization_id || key.within_organization_boundary?(project.organization)
    end
  end
end

Projects::EnableDeployKeyService.prepend_mod_with('Projects::EnableDeployKeyService')
