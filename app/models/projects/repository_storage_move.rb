# frozen_string_literal: true

# Projects::RepositoryStorageMove are details of repository storage moves for a
# project. For example, moving a project to another gitaly node to help
# balance storage capacity.
module Projects
  class RepositoryStorageMove < ApplicationRecord
    extend ::Gitlab::Utils::Override
    include RepositoryStorageMovable

    self.table_name = 'project_repository_storage_moves'

    belongs_to :container, class_name: 'Project', inverse_of: :repository_storage_moves, foreign_key: :project_id
    alias_method :project, :container

    alias_attribute :container_id, :project_id
    scope :with_projects, -> { includes(container: :route) }

    override :schedule_repository_storage_update_worker
    def schedule_repository_storage_update_worker
      Projects::UpdateRepositoryStorageWorker.perform_async(id)
    end

    private

    override :error_key
    def error_key
      :project
    end
  end
end
