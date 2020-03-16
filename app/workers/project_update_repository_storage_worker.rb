# frozen_string_literal: true

class ProjectUpdateRepositoryStorageWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  feature_category :gitaly

  def perform(project_id, new_repository_storage_key)
    project = Project.find(project_id)

    ::Projects::UpdateRepositoryStorageService.new(project).execute(new_repository_storage_key)
  end
end
