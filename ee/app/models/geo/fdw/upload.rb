module Geo
  module Fdw
    class Upload < ::Geo::BaseFdw
      self.table_name = Gitlab::Geo::Fdw.table('uploads')

      scope :with_files_stored_locally, -> { where(store: [nil, ObjectStorage::Store::LOCAL]) }
    end
  end
end
