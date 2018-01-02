module Geo
  class FileRegistryFinder < RegistryFinder
    def find_failed_file_registries(batch_size:)
      Geo::FileRegistry.failed.retry_due.limit(batch_size)
    end

    protected

    def legacy_pluck_registry_ids(file_types:, except_registry_ids:)
      ids = Geo::FileRegistry.where(file_type: file_types).pluck(:file_id)
      (ids + except_registry_ids).uniq
    end
  end
end
