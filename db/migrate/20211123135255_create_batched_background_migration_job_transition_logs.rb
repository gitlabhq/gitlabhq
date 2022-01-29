# frozen_string_literal: true

class CreateBatchedBackgroundMigrationJobTransitionLogs < Gitlab::Database::Migration[1.0]
  include Gitlab::Database::PartitioningMigrationHelpers

  def up
    execute(<<~SQL)
      CREATE TABLE batched_background_migration_job_transition_logs (
        id bigserial NOT NULL,
        batched_background_migration_job_id bigint NOT NULL,
        created_at timestamp with time zone NOT NULL,
        updated_at timestamp with time zone NOT NULL,
        previous_status smallint NOT NULL,
        next_status smallint NOT NULL,
        exception_class text,
        exception_message text,
        CONSTRAINT check_50e580811a CHECK ((char_length(exception_message) <= 1000)),
        CONSTRAINT check_76e202c37a CHECK ((char_length(exception_class) <= 100)),
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);

      CREATE INDEX i_batched_background_migration_job_transition_logs_on_job_id
        ON batched_background_migration_job_transition_logs USING btree (batched_background_migration_job_id);

      ALTER TABLE batched_background_migration_job_transition_logs ADD CONSTRAINT fk_rails_b7523a175b
        FOREIGN KEY (batched_background_migration_job_id) REFERENCES batched_background_migration_jobs(id) ON DELETE CASCADE;
    SQL

    min_date = Date.today
    max_date = Date.today + 6.months

    create_daterange_partitions('batched_background_migration_job_transition_logs', 'created_at', min_date, max_date)
  end

  def down
    drop_table :batched_background_migration_job_transition_logs
  end
end
