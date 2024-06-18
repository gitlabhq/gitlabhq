# frozen_string_literal: true

class AddUniqueIndexOnStatusToCiPartition < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.1'

  TABLE_NAME = :ci_partitions
  INDEX_NAME = :index_ci_partitions_on_current_status
  CURRENT_STATUS = 2

  def up
    add_concurrent_index(TABLE_NAME, :status, unique: true, where: "status = #{CURRENT_STATUS}", name: INDEX_NAME)
  end

  def down
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end
end
