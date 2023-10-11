# frozen_string_literal: true

class ReplaceValueStreamProjectIdsFilterConstraint < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    execute <<~SQL
      ALTER TABLE analytics_cycle_analytics_value_stream_settings
        DROP CONSTRAINT IF EXISTS chk_rails_a91b547c97;

      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1
            FROM information_schema.constraint_column_usage
            WHERE table_name = 'analytics_cycle_analytics_value_stream_settings'
            AND constraint_name = 'project_ids_filter_array_check'
        ) THEN
          ALTER TABLE analytics_cycle_analytics_value_stream_settings
            ADD CONSTRAINT project_ids_filter_array_check
            CHECK ((CARDINALITY(project_ids_filter) <= 100) AND (ARRAY_POSITION(project_ids_filter, null) IS null));
        END IF;
      END $$
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE analytics_cycle_analytics_value_stream_settings
        DROP CONSTRAINT IF EXISTS project_ids_filter_array_check;

      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1
            FROM information_schema.constraint_column_usage
            WHERE table_name = 'analytics_cycle_analytics_value_stream_settings'
            AND constraint_name = 'chk_rails_a91b547c97'
        ) THEN
          ALTER TABLE analytics_cycle_analytics_value_stream_settings
            ADD CONSTRAINT chk_rails_a91b547c97
            CHECK (CARDINALITY(project_ids_filter) <= 100);
        END IF;
      END $$
    SQL
  end
end
