class AddFileRegistrySuccess < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # Ensure existing rows are recorded as successes
    add_column_with_default :file_registry, :success, :boolean, default: true, allow_null: false

    change_column :file_registry, :success, :boolean, default: false
  end

  def down
    # Prevent failures from being converted into successes
    false_value = Arel::Nodes::False.new.to_sql(Geo::BaseRegistry)
    connection.execute("DELETE FROM file_registry WHERE success = #{false_value}")

    remove_column :file_registry, :success
  end
end
