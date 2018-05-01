module Geo
  module Fdw
    module Ci
      class JobArtifact < ::Geo::BaseFdw
        self.table_name = Gitlab::Geo::Fdw.table('ci_job_artifacts')

        scope :with_files_stored_locally, -> { where(file_store: [nil, JobArtifactUploader::Store::LOCAL]) }
        scope :with_files_stored_remotely, -> { where(file_store: JobArtifactUploader::Store::REMOTE) }
        scope :not_expired, -> { where('expire_at IS NULL OR expire_at > ?', Time.current) }
        scope :geo_syncable, -> { with_files_stored_locally.not_expired }
      end
    end
  end
end
