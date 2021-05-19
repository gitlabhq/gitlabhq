# frozen_string_literal: true

module Projects
  class DisableDeployKeyService < BaseService
    def execute
      # rubocop: disable CodeReuse/ActiveRecord
      deploy_key_project = project.deploy_keys_projects.find_by(deploy_key_id: params[:id])
      # rubocop: enable CodeReuse/ActiveRecord

      deploy_key_project&.destroy!
    end
  end
end

Projects::DisableDeployKeyService.prepend_mod_with('Projects::DisableDeployKeyService')
