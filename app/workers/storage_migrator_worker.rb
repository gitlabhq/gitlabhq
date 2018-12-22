# frozen_string_literal: true

class StorageMigratorWorker
  include ApplicationWorker

  # @param [Integer] start initial ID of the batch
  # @param [Integer] finish last ID of the batch
  # @param [String] operation the operation to be performed: ['migrate', 'rollback']
  def perform(start, finish, operation = :migrate)
    # when scheduling a job symbols are converted to string, we need to convert back
    operation = operation.to_sym if operation

    migrator = Gitlab::HashedStorage::Migrator.new
    migrator.bulk_migrate(start: start, finish: finish, operation: operation)
  end
end
