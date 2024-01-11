# frozen_string_literal: true

class AddTemporaryIndexInternalIdsOnIdAndUsage < Gitlab::Database::Migration[2.2]
  milestone '16.8'
  disable_ddl_transaction!

  INDEX_NAME = "tmp_index_internal_ids_on_id_and_usage"
  EPICS_USAGE = 4 # see Enums::InternalId#usage_resources[:epics]

  def up
    add_concurrent_index :internal_ids, :id, name: INDEX_NAME, where: "usage = #{EPICS_USAGE}"
  end

  def down
    remove_concurrent_index_by_name :internal_ids, name: INDEX_NAME
  end
end
