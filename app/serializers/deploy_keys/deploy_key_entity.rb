# frozen_string_literal: true

module DeployKeys
  class DeployKeyEntity < BasicDeployKeyEntity
    expose :deploy_keys_projects, using: DeployKeysProjectEntity do |deploy_key|
      deploy_key.deploy_keys_projects.select do |deploy_key_project|
        !deploy_key_project.project&.pending_delete? &&
          (allowed_to_read_project?(deploy_key_project.project) || options[:user].can_admin_all_resources?)
      end
    end

    private

    def allowed_to_read_project?(project)
      if options[:readable_project_ids]
        options[:readable_project_ids].include?(project.id)
      else
        Ability.allowed?(options[:user], :read_project, project)
      end
    end
  end
end
