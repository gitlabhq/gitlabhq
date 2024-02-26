# frozen_string_literal: true

class EnsureIdUniquenessForPCiStages < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers

  milestone '16.10'
  enable_lock_retries!

  TABLE_NAME = :p_ci_stages
  FUNCTION_NAME = :assign_p_ci_stages_id_value

  def up
    ensure_unique_id(TABLE_NAME)
  end

  def down
    execute(<<~SQL.squish)
      ALTER TABLE #{TABLE_NAME}
        ALTER COLUMN id SET DEFAULT nextval('ci_stages_id_seq'::regclass);

      DROP FUNCTION IF EXISTS #{FUNCTION_NAME} CASCADE;
    SQL
  end
end
