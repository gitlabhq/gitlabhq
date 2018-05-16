module Geo
  module Fdw
    class Upload < ::Geo::BaseFdw
      include ObjectStorable

      STORE_COLUMN = :store

      self.table_name = Gitlab::Geo::Fdw.table('uploads')

      scope :geo_syncable, -> { with_files_stored_locally }
    end
  end
end
