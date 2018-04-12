class MigrateCiJobArtifactsToSeparateRegistry < ActiveRecord::Migration
  def up
    tracking_db.create_table :job_artifact_registry, force: :cascade do |t|
      t.datetime_with_timezone "created_at"
      t.datetime_with_timezone "retry_at"
      t.integer "bytes", limit: 8
      t.integer "artifact_id", unique: true
      t.integer "retry_count"
      t.boolean "success"
      t.string "sha256"
    end

    Geo::TrackingBase.transaction do
      execute('LOCK TABLE file_registry IN EXCLUSIVE MODE')

      execute <<~EOF
          INSERT INTO job_artifact_registry (created_at, retry_at, artifact_id, bytes, retry_count, success, sha256)
          SELECT created_at, retry_at, file_id, bytes, retry_count, success, sha256
          FROM file_registry WHERE file_type = 'job_artifact'
      EOF

      execute <<~EOF
          CREATE OR REPLACE FUNCTION replicate_job_artifact_registry()
          RETURNS trigger AS
          $BODY$
          BEGIN
              IF (TG_OP = 'UPDATE') THEN
                  UPDATE job_artifact_registry
                  SET (retry_at, bytes, retry_count, success, sha256) =
                      (NEW.retry_at, NEW.bytes, NEW.retry_count, NEW.success, NEW.sha256)
                  WHERE artifact_id = NEW.file_id;
              ELSEIF (TG_OP = 'INSERT') THEN
                  INSERT INTO job_artifact_registry (created_at, retry_at, artifact_id, bytes, retry_count, success, sha256)
                  VALUES (NEW.created_at, NEW.retry_at, NEW.file_id, NEW.bytes, NEW.retry_count, NEW.success, NEW.sha256);
          END IF;
          RETURN NEW;
          END;
          $BODY$
          LANGUAGE 'plpgsql'
          VOLATILE;
          EOF

      execute <<~EOF
          CREATE TRIGGER replicate_job_artifact_registry
          AFTER INSERT OR UPDATE ON file_registry
          FOR EACH ROW WHEN (NEW.file_type = 'job_artifact') EXECUTE PROCEDURE replicate_job_artifact_registry();
      EOF
    end

    tracking_db.add_index :job_artifact_registry, :retry_at
    tracking_db.add_index :job_artifact_registry, :success
  end

  def down
    tracking_db.drop_table :job_artifact_registry
    execute('DROP TRIGGER IF EXISTS replicate_job_artifact_registry ON file_registry')
    execute('DROP FUNCTION IF EXISTS replicate_job_artifact_registry()')
  end

  def execute(statement)
    tracking_db.execute(statement)
  end

  def tracking_db
    Geo::TrackingBase.connection
  end
end
