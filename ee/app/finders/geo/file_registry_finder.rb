module Geo
  class FileRegistryFinder < RegistryFinder
    protected

    def legacy_pluck_registry_file_ids(file_types:)
      Geo::FileRegistry.where(file_type: file_types).pluck(:file_id)
    end
  end
end
