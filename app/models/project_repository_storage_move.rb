# frozen_string_literal: true

# ProjectRepositoryStorageMove are details of repository storage moves for a
# project. For example, moving a project to another gitaly node to help
# balance storage capacity.
class ProjectRepositoryStorageMove < ApplicationRecord
  extend ::Gitlab::Utils::Override
  include RepositoryStorageMovable

  belongs_to :container, class_name: 'Project', inverse_of: :repository_storage_moves, foreign_key: :project_id
  alias_attribute :project, :container
  scope :with_projects, -> { includes(container: :route) }

  override :update_repository_storage
  def update_repository_storage(new_storage)
    container.update_column(:repository_storage, new_storage)
  end

  override :schedule_repository_storage_update_worker
  def schedule_repository_storage_update_worker
    ProjectUpdateRepositoryStorageWorker.perform_async(
      project_id,
      destination_storage_name,
      id
    )
  end

  private

  override :error_key
  def error_key
    :project
  end
end
