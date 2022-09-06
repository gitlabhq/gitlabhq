# frozen_string_literal: true

# rubocop:disable Migration/WithLockRetriesDisallowedMethod
class MoveSecurityFindingsTableToGitlabPartitionsDynamicSchema < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_MAPPING_OF_PARTITION = {
    index_security_findings_on_unique_columns: :security_findings_1_uuid_scan_id_partition_number_idx,
    index_security_findings_on_confidence: :security_findings_1_confidence_idx,
    index_security_findings_on_project_fingerprint: :security_findings_1_project_fingerprint_idx,
    index_security_findings_on_scan_id_and_deduplicated: :security_findings_1_scan_id_deduplicated_idx,
    index_security_findings_on_scan_id_and_id: :security_findings_1_scan_id_id_idx,
    index_security_findings_on_scanner_id: :security_findings_1_scanner_id_idx,
    index_security_findings_on_severity: :security_findings_1_severity_idx
  }.freeze

  INDEX_MAPPING_AFTER_CREATING_FROM_PARTITION = {
    partition_name_placeholder_pkey: :security_findings_pkey,
    partition_name_placeholder_uuid_scan_id_partition_number_idx: :index_security_findings_on_unique_columns,
    partition_name_placeholder_confidence_idx: :index_security_findings_on_confidence,
    partition_name_placeholder_project_fingerprint_idx: :index_security_findings_on_project_fingerprint,
    partition_name_placeholder_scan_id_deduplicated_idx: :index_security_findings_on_scan_id_and_deduplicated,
    partition_name_placeholder_scan_id_id_idx: :index_security_findings_on_scan_id_and_id,
    partition_name_placeholder_scanner_id_idx: :index_security_findings_on_scanner_id,
    partition_name_placeholder_severity_idx: :index_security_findings_on_severity
  }.freeze

  INDEX_MAPPING_AFTER_CREATING_FROM_ITSELF = {
    security_findings_pkey1: :security_findings_pkey,
    security_findings_uuid_scan_id_partition_number_idx1: :index_security_findings_on_unique_columns,
    security_findings_confidence_idx1: :index_security_findings_on_confidence,
    security_findings_project_fingerprint_idx1: :index_security_findings_on_project_fingerprint,
    security_findings_scan_id_deduplicated_idx1: :index_security_findings_on_scan_id_and_deduplicated,
    security_findings_scan_id_id_idx1: :index_security_findings_on_scan_id_and_id,
    security_findings_scanner_id_idx1: :index_security_findings_on_scanner_id,
    security_findings_severity_idx1: :index_security_findings_on_severity
  }.freeze

  LATEST_PARTITION_SQL = <<~SQL
    SELECT
      partitions.relname AS partition_name
    FROM pg_inherits
    JOIN pg_class parent ON pg_inherits.inhparent = parent.oid
    JOIN pg_class partitions ON pg_inherits.inhrelid = partitions.oid
    WHERE
      parent.relname = 'security_findings'
    ORDER BY (regexp_matches(partitions.relname, 'security_findings_(\\d+)'))[1]::int DESC
    LIMIT 1
  SQL

  CURRENT_CHECK_CONSTRAINT_SQL = <<~SQL
    SELECT
      pg_get_constraintdef(pg_catalog.pg_constraint.oid)
    FROM
      pg_catalog.pg_constraint
    INNER JOIN pg_class ON pg_class.oid = pg_catalog.pg_constraint.conrelid
    WHERE
      conname = 'check_partition_number' AND
      pg_class.relname = 'security_findings'
  SQL

  def up
    with_lock_retries do
      lock_tables

      execute(<<~SQL)
        ALTER TABLE security_findings RENAME TO security_findings_#{candidate_partition_number};
      SQL

      execute(<<~SQL)
        ALTER INDEX security_findings_pkey RENAME TO security_findings_#{candidate_partition_number}_pkey;
      SQL

      execute(<<~SQL)
        CREATE TABLE security_findings (
          LIKE security_findings_#{candidate_partition_number} INCLUDING ALL
        ) PARTITION BY LIST (partition_number);
      SQL

      execute(<<~SQL)
        ALTER SEQUENCE security_findings_id_seq OWNED BY #{connection.current_schema}.security_findings.id;
      SQL

      execute(<<~SQL)
        ALTER TABLE security_findings
        ADD CONSTRAINT fk_rails_729b763a54 FOREIGN KEY (scanner_id) REFERENCES vulnerability_scanners(id) ON DELETE CASCADE;
      SQL

      execute(<<~SQL)
        ALTER TABLE security_findings
        ADD CONSTRAINT fk_rails_bb63863cf1 FOREIGN KEY (scan_id) REFERENCES security_scans(id) ON DELETE CASCADE;
      SQL

      execute(<<~SQL)
        ALTER TABLE security_findings_#{candidate_partition_number} SET SCHEMA gitlab_partitions_dynamic;
      SQL

      execute(<<~SQL)
        ALTER TABLE security_findings ATTACH PARTITION gitlab_partitions_dynamic.security_findings_#{candidate_partition_number} FOR VALUES IN (#{candidate_partition_number});
      SQL

      execute(<<~SQL)
        ALTER TABLE security_findings DROP CONSTRAINT check_partition_number;
      SQL

      index_mapping = INDEX_MAPPING_OF_PARTITION.transform_values do |value|
        value.to_s.sub('partition_name_placeholder', "security_findings_#{candidate_partition_number}")
      end

      rename_indices('gitlab_partitions_dynamic', index_mapping)
    end
  end

  def down
    # If there is already a partition for the `security_findings` table,
    # we can promote that table to be the original one to save the data.
    # Otherwise, we have to bring back the non-partitioned `security_findings`
    # table from the partitioned one.
    if latest_partition
      create_non_partitioned_security_findings_with_data
    else
      create_non_partitioned_security_findings_without_data
    end
  end

  private

  def lock_tables
    execute(<<~SQL)
      LOCK TABLE vulnerability_scanners, security_scans, security_findings IN ACCESS EXCLUSIVE MODE
    SQL
  end

  def current_check_constraint
    execute(CURRENT_CHECK_CONSTRAINT_SQL).first['pg_get_constraintdef']
  end

  def candidate_partition_number
    @candidate_partition_number ||= current_check_constraint.match(/partition_number\s?=\s?(\d+)/).captures.first
  end

  def latest_partition
    @latest_partition ||= execute(LATEST_PARTITION_SQL).first&.fetch('partition_name', nil)
  end

  def latest_partition_number
    latest_partition.match(/security_findings_(\d+)/).captures.first
  end

  # rubocop:disable Migration/DropTable (These methods are called from the `down` method)
  def create_non_partitioned_security_findings_with_data
    with_lock_retries do
      lock_tables

      execute(<<~SQL)
        ALTER TABLE security_findings DETACH PARTITION gitlab_partitions_dynamic.#{latest_partition};
      SQL

      execute(<<~SQL)
        ALTER TABLE gitlab_partitions_dynamic.#{latest_partition} SET SCHEMA #{connection.current_schema};
      SQL

      execute(<<~SQL)
        ALTER SEQUENCE security_findings_id_seq OWNED BY #{latest_partition}.id;
      SQL

      execute(<<~SQL)
        DROP TABLE security_findings;
      SQL

      execute(<<~SQL)
        ALTER TABLE #{latest_partition} RENAME TO security_findings;
      SQL

      index_mapping = INDEX_MAPPING_AFTER_CREATING_FROM_PARTITION.transform_keys do |key|
        key.to_s.sub('partition_name_placeholder', latest_partition)
      end

      rename_indices(connection.current_schema, index_mapping)
    end

    add_check_constraint(:security_findings, "(partition_number = #{latest_partition_number})", :check_partition_number)
  end

  def create_non_partitioned_security_findings_without_data
    with_lock_retries do
      lock_tables

      execute(<<~SQL)
        ALTER TABLE security_findings RENAME TO security_findings_1;
      SQL

      execute(<<~SQL)
        CREATE TABLE security_findings (
          LIKE security_findings_1 INCLUDING ALL
        );
      SQL

      execute(<<~SQL)
        ALTER SEQUENCE security_findings_id_seq OWNED BY #{connection.current_schema}.security_findings.id;
      SQL

      execute(<<~SQL)
        DROP TABLE security_findings_1;
      SQL

      execute(<<~SQL)
        ALTER TABLE ONLY security_findings
        ADD CONSTRAINT fk_rails_729b763a54 FOREIGN KEY (scanner_id) REFERENCES vulnerability_scanners(id) ON DELETE CASCADE;
      SQL

      execute(<<~SQL)
        ALTER TABLE ONLY security_findings
        ADD CONSTRAINT fk_rails_bb63863cf1 FOREIGN KEY (scan_id) REFERENCES security_scans(id) ON DELETE CASCADE;
      SQL

      rename_indices(connection.current_schema, INDEX_MAPPING_AFTER_CREATING_FROM_ITSELF)
    end

    add_check_constraint(:security_findings, "(partition_number = 1)", :check_partition_number)
  end

  def rename_indices(schema, mapping)
    mapping.each do |index_name, new_index_name|
      execute(<<~SQL)
        ALTER INDEX #{schema}.#{index_name} RENAME TO #{new_index_name};
      SQL
    end
  end
  # rubocop:enable Migration/DropTable
end
# rubocop:enable Migration/WithLockRetriesDisallowedMethod
