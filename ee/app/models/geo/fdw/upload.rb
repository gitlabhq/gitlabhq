module Geo
  module Fdw
    class Upload < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo.fdw_table('uploads')

      scope :with_files_stored_locally, -> { where(store: [nil, ObjectStorage::Store::LOCAL]) }
    end
  end
end
