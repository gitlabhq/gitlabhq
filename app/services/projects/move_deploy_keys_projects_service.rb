# frozen_string_literal: true

module Projects
  class MoveDeployKeysProjectsService < BaseMoveRelationsService
    def execute(source_project, remove_remaining_elements: true)
      return unless super

      # The SHA256 fingerprint should be there, but just in case it isn't
      # we want to make sure it's generated. Otherwise we might delete keys.
      ensure_sha256_fingerprints

      Project.transaction do
        move_deploy_keys_projects
        remove_remaining_deploy_keys_projects if remove_remaining_elements

        success
      end
    end

    private

    def ensure_sha256_fingerprints
      @project.deploy_keys.each(&:ensure_sha256_fingerprint!)
      source_project.deploy_keys.each(&:ensure_sha256_fingerprint!)
    end

    def move_deploy_keys_projects
      non_existent_deploy_keys_projects.update_all(project_id: @project.id)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def non_existent_deploy_keys_projects
      source_project.deploy_keys_projects
                    .joins(:deploy_key)
                    .where.not(keys: { fingerprint_sha256: @project.deploy_keys.select(:fingerprint_sha256) })
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def remove_remaining_deploy_keys_projects
      source_project.deploy_keys_projects.destroy_all # rubocop: disable Cop/DestroyAll
    end
  end
end
