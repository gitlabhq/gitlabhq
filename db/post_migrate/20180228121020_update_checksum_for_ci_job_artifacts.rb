class UpdateChecksumForCiJobArtifacts < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  BATCH_SIZE = 2500

  class JobArtifact < ActiveRecord::Base
    include EachBatch
    self.table_name = 'ci_job_artifacts'
  end

  def up
    UpdateChecksumForCiJobArtifacts::JobArtifact
      .where('checksum IS NULL')
      .each_batch(of: BATCH_SIZE) do |relation|
      ids = relation.pluck(:id).map { |id| [id] }

      UpdateArtifactChecksumWorker.bulk_perform_async(ids)
    end
  end

  def down
    # no-op
  end
end
