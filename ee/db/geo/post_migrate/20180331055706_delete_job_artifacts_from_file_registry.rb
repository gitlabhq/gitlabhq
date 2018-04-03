class DeleteJobArtifactsFromFileRegistry < ActiveRecord::Migration
  def up
    execute("DELETE FROM file_registry WHERE file_type = 'job_artifact'")
    execute('DROP TRIGGER IF EXISTS replicate_job_artifact_registry ON file_registry')
    execute('DROP FUNCTION IF EXISTS replicate_job_artifact_registry()')
  end
end
