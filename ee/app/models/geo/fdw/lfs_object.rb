module Geo
  module Fdw
    class LfsObject < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo.fdw_table('lfs_objects')

      scope :with_files_stored_locally, -> { where(file_store: [nil, LfsObjectUploader::LOCAL_STORE]) }
    end
  end
end
