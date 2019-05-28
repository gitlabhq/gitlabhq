# frozen_string_literal: true

module HashedStorage
  class RollbackerWorker
    include ApplicationWorker

    queue_namespace :hashed_storage

    # @param [Integer] start initial ID of the batch
    # @param [Integer] finish last ID of the batch
    def perform(start, finish)
      migrator = Gitlab::HashedStorage::Migrator.new
      migrator.bulk_rollback(start: start, finish: finish)
    end
  end
end
