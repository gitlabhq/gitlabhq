# frozen_string_literal: true

class DeployKeyEntity < Grape::Entity
  expose :id
  expose :user_id
  expose :title
  expose :fingerprint
  expose :destroyed_when_orphaned?, as: :destroyed_when_orphaned
  expose :almost_orphaned?, as: :almost_orphaned
  expose :created_at
  expose :updated_at
  expose :deploy_keys_projects, using: DeployKeysProjectEntity do |deploy_key|
    deploy_key.deploy_keys_projects.select do |deploy_key_project|
      !deploy_key_project.project&.pending_delete? && (allowed_to_read_project?(deploy_key_project.project) || options[:user].admin?)
    end
  end
  expose :can_edit

  private

  def can_edit
    Ability.allowed?(options[:user], :update_deploy_key, object) ||
      Ability.allowed?(options[:user], :update_deploy_keys_project, object.deploy_keys_project_for(options[:project]))
  end

  def allowed_to_read_project?(project)
    if options[:readable_project_ids]
      options[:readable_project_ids].include?(project.id)
    else
      Ability.allowed?(options[:user], :read_project, project)
    end
  end
end
