# frozen_string_literal: true

module Projects
  class EnableDeployKeyService < BaseService
    def execute
      key = accessible_keys.find_by(id: params[:key_id] || params[:id])
      return unless key

      unless project.deploy_keys.include?(key)
        project.deploy_keys << key
      end

      key
    end

    private

    def accessible_keys
      current_user.accessible_deploy_keys
    end
  end
end
