# frozen_string_literal: true

class EnsureIdUniquenessForPCiBuildsV3 < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::SchemaHelpers

  enable_lock_retries!

  TABLE_NAME = :p_ci_builds
  FUNCTION_NAME = :assign_p_ci_builds_id_value
  TRIGGER_NAME = :assign_p_ci_builds_id_trigger

  def up
    return if trigger_exists?(:ci_builds, TRIGGER_NAME)

    change_column_default(TABLE_NAME, :id, nil)

    create_trigger_function(FUNCTION_NAME) do
      <<~SQL
        IF NEW."id" IS NOT NULL THEN
          RAISE WARNING 'Manually assigning ids is not allowed, the value will be ignored';
        END IF;
        NEW."id" := nextval('ci_builds_id_seq'::regclass);
        RETURN NEW;
      SQL
    end

    Gitlab::Database::PostgresPartitionedTable.each_partition(TABLE_NAME) do |partition|
      create_trigger(partition.identifier, TRIGGER_NAME, FUNCTION_NAME, fires: 'BEFORE INSERT')
    end
  end

  def down
    execute(<<~SQL.squish)
      ALTER TABLE #{TABLE_NAME}
        ALTER COLUMN id SET DEFAULT nextval('ci_builds_id_seq'::regclass);

      DROP FUNCTION IF EXISTS #{FUNCTION_NAME} CASCADE;
    SQL
  end
end
