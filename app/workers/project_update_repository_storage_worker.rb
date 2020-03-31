# frozen_string_literal: true

class ProjectUpdateRepositoryStorageWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  SameFilesystemError = Class.new(StandardError)

  feature_category :gitaly

  def perform(project_id, new_repository_storage_key)
    project = Project.find(project_id)

    raise SameFilesystemError if same_filesystem?(project.repository.storage, new_repository_storage_key)

    ::Projects::UpdateRepositoryStorageService.new(project).execute(new_repository_storage_key)
  end

  private

  def same_filesystem?(old_storage, new_storage)
    Gitlab::GitalyClient.filesystem_id(old_storage) == Gitlab::GitalyClient.filesystem_id(new_storage)
  end
end
