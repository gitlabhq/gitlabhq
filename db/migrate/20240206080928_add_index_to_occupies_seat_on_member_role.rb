# frozen_string_literal: true

class AddIndexToOccupiesSeatOnMemberRole < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  disable_ddl_transaction!

  INDEX_NAME = 'index_member_roles_on_occupies_seat'

  def up
    add_concurrent_index :member_roles, :occupies_seat, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :member_roles, name: INDEX_NAME
  end
end
