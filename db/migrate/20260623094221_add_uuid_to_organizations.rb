# frozen_string_literal: true

class AddUuidToOrganizations < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!

  milestone '19.2'

  def up
    with_lock_retries do
      add_column :organizations, :uuid, :uuid, default: -> { 'gen_random_uuid_v7()' }, null: false, if_not_exists: true
    end
  end

  def down
    with_lock_retries do
      remove_column :organizations, :uuid, if_exists: true
    end
  end
end
