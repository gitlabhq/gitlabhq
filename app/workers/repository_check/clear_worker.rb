module RepositoryCheck
  class ClearWorker
    include Sidekiq::Worker
    include RepositoryCheckQueue

    def perform
      # Do small batched updates because these updates will be slow and locking
      Project.select(:id).find_in_batches(batch_size: 100) do |batch|
        Project.where(id: batch.map(&:id)).update_all(
          last_repository_check_failed: nil,
          last_repository_check_at: nil,
        )
      end
    end
  end
end
