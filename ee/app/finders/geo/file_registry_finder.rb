module Geo
  class FileRegistryFinder < RegistryFinder
    # @abstract Subclass is expected to implement the declared methods

    # @!method syncable
    #    Return an ActiveRecord::Relation of tracked resource records, filtered
    #    by selective sync, with files stored locally
    def syncable
      raise NotImplementedError
    end

    # @!method count_syncable
    #    Return a count of tracked resource records, filtered by selective
    #    sync, with files stored locally
    def count_syncable
      raise NotImplementedError
    end

    # @!method count_synced
    #    Return a count of tracked resource records, filtered by selective
    #    sync, with files stored locally, and are synced
    def count_synced
      raise NotImplementedError
    end

    # @!method count_failed
    #    Return a count of tracked resource records, filtered by selective
    #    sync, with files stored locally, and are failed
    def count_failed
      raise NotImplementedError
    end

    # @!method count_synced_missing_on_primary
    #    Return a count of tracked resource records, filtered by selective
    #    sync, with files stored locally, and are synced and missing on the
    #    primary
    def count_synced_missing_on_primary
      raise NotImplementedError
    end

    # @!method count_registry
    #    Return a count of the registry records for the tracked file_type(s)
    def count_registry
      raise NotImplementedError
    end

    # @!method find_unsynced
    #    Return an ActiveRecord::Relation of not-yet-tracked resource records,
    #    filtered by selective sync, with files stored locally, excluding
    #    specified IDs, limited to batch_size
    def find_unsynced
      raise NotImplementedError
    end

    # @!method find_migrated_local
    #    Return an ActiveRecord::Relation of tracked resource records, filtered
    #    by selective sync, with files stored remotely, excluding
    #    specified IDs, limited to batch_size
    def find_migrated_local
      raise NotImplementedError
    end

    # @!method find_retryable_failed_registries
    #    Return an ActiveRecord::Relation of registry records marked as failed,
    #    which are ready to be retried, excluding specified IDs, limited to
    #    batch_size
    def find_retryable_failed_registries
      raise NotImplementedError
    end

    # @!method find_retryable_synced_missing_on_primary_registries
    #    Return an ActiveRecord::Relation of registry records marked as synced
    #    and missing on the primary, which are ready to be retried, excluding
    #    specified IDs, limited to batch_size
    def find_retryable_synced_missing_on_primary_registries
      raise NotImplementedError
    end
  end
end
