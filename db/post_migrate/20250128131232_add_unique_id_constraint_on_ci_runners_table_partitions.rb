# frozen_string_literal: true

class AddUniqueIdConstraintOnCiRunnersTablePartitions < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.9'

  TABLE_NAMES =
    %w[instance_type_ci_runners_e59bb2812d group_type_ci_runners_e59bb2812d project_type_ci_runners_e59bb2812d]
  COLUMN_NAME = :id

  def up
    TABLE_NAMES.each do |table_name|
      with_lock_retries do
        execute <<~SQL
          ALTER TABLE #{table_name}
          ADD CONSTRAINT #{constraint_name(table_name)}
          UNIQUE( #{COLUMN_NAME} );
        SQL
      end
    end
  end

  def down
    TABLE_NAMES.each do |table_name|
      with_lock_retries do
        execute <<~SQL
          ALTER TABLE #{table_name}
          DROP CONSTRAINT #{constraint_name(table_name)};
        SQL
      end
    end
  end

  private

  def constraint_name(table_name)
    check_constraint_name(table_name, COLUMN_NAME, 'unique_id')
  end
end
