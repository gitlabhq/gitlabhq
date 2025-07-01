# frozen_string_literal: true

class AddSourceIdToFrameworks < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    with_lock_retries do
      add_column :compliance_management_frameworks, :source_id, :bigint
    end
  end

  def down
    with_lock_retries do
      remove_column :compliance_management_frameworks, :source_id, if_exists: true
    end
  end
end
