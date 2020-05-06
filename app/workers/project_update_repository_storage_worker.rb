# frozen_string_literal: true

class ProjectUpdateRepositoryStorageWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :gitaly

  def perform(project_id, new_repository_storage_key, repository_storage_move_id: nil)
    repository_storage_move =
      if repository_storage_move_id
        ProjectRepositoryStorageMove.find(repository_storage_move_id)
      else
        # maintain compatibility with workers queued before release
        project = Project.find(project_id)
        project.repository_storage_moves.create!(
          source_storage_name: project.repository_storage,
          destination_storage_name: new_repository_storage_key
        )
      end

    ::Projects::UpdateRepositoryStorageService.new(repository_storage_move).execute
  end
end
