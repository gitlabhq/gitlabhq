module Geo
  module Fdw
    module Ci
      class JobArtifact < ::Geo::BaseFdw
        include ObjectStorable

        STORE_COLUMN = :file_store

        self.table_name = Gitlab::Geo::Fdw.table('ci_job_artifacts')

        scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
        scope :geo_syncable, -> { with_files_stored_locally.not_expired }
      end
    end
  end
end
