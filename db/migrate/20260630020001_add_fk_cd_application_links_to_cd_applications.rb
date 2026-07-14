# frozen_string_literal: true

class AddFkCdApplicationLinksToCdApplications < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.2'

  def up
    add_concurrent_foreign_key :cd_application_links, :cd_applications, column: :application_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :cd_application_links, column: :application_id
    end
  end
end
