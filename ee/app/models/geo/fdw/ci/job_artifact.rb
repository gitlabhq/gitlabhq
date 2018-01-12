module Geo
  module Fdw
    module Ci
      class JobArtifact < ::Geo::BaseFdw
        self.table_name = Gitlab::Geo.fdw_table('ci_job_artifacts')

        scope :with_files_stored_locally, -> { where(file_store: [nil, JobArtifactUploader::LOCAL_STORE]) }
      end
    end
  end
end
