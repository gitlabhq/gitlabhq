# frozen_string_literal: true

module UpdateRepositoryStorageWorker
  extend ActiveSupport::Concern
  include ApplicationWorker

  included do
    idempotent!
    feature_category :gitaly
    urgency :throttled
  end

  def perform(container_id, new_repository_storage_key, repository_storage_move_id = nil)
    repository_storage_move =
      if repository_storage_move_id
        find_repository_storage_move(repository_storage_move_id)
      else
        # maintain compatibility with workers queued before release
        container = find_container(container_id)
        container.repository_storage_moves.create!(
          source_storage_name: container.repository_storage,
          destination_storage_name: new_repository_storage_key
        )
      end

    update_repository_storage(repository_storage_move)
  end

  private

  def find_repository_storage_move(repository_storage_move_id)
    raise NotImplementedError
  end

  def find_container(container_id)
    raise NotImplementedError
  end

  def update_repository_storage(repository_storage_move)
    raise NotImplementedError
  end
end
