module Geo
  module Fdw
    class LfsObject < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.table('lfs_objects')

      scope :with_files_stored_locally, -> { where(file_store: [nil, LfsObjectUploader::Store::LOCAL]) }
      scope :with_files_stored_remotely, -> { where(file_store: LfsObjectUploader::Store::REMOTE) }
    end
  end
end
