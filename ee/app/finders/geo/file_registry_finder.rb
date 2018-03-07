module Geo
  class FileRegistryFinder < RegistryFinder
    def find_failed_file_registries(batch_size:)
      Geo::FileRegistry.failed.retry_due.limit(batch_size)
    end

    protected

    def legacy_pluck_registry_file_ids(file_types:)
      Geo::FileRegistry.where(file_type: file_types).pluck(:file_id)
    end
  end
end
