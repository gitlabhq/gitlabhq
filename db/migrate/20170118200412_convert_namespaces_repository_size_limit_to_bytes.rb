# rubocop:disable Migration/RemoveColumn
# rubocop:disable Migration/UpdateColumnInBatches
# rubocop:disable Migration/UpdateLargeTable
class ConvertNamespacesRepositorySizeLimitToBytes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  disable_ddl_transaction!

  def up
    connection.transaction do
      rename_column :namespaces, :repository_size_limit, :repository_size_limit_mb
      add_column :namespaces, :repository_size_limit, :integer, limit: 8
    end

    bigint_string = if Gitlab::Database.postgresql?
                      'repository_size_limit_mb::bigint * 1024 * 1024'
                    else
                      'repository_size_limit_mb * 1024 * 1024'
                    end

    sql_expression = Arel::Nodes::SqlLiteral.new(bigint_string)

    update_column_in_batches(:namespaces, :repository_size_limit, sql_expression) do |t, query|
      query.where(t[:repository_size_limit_mb].not_eq(nil))
    end

    remove_column :namespaces, :repository_size_limit_mb
  end

  def down
    connection.transaction do
      rename_column :namespaces, :repository_size_limit, :repository_size_limit_bytes
      add_column :namespaces, :repository_size_limit, :integer, limit: nil
    end

    sql_expression = Arel::Nodes::SqlLiteral.new('repository_size_limit_bytes / 1024 / 1024')

    update_column_in_batches(:namespaces, :repository_size_limit, sql_expression) do |t, query|
      query.where(t[:repository_size_limit_bytes].not_eq(nil))
    end

    remove_column :namespaces, :repository_size_limit_bytes
  end
end
