# frozen_string_literal: true

class AddForeginKeyApplicationMicrosoftGraphAccessTokens < Gitlab::Database::Migration[2.2]
  milestone '17.7'
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :system_access_group_microsoft_graph_access_tokens,
      :system_access_group_microsoft_applications,
      column: :system_access_group_microsoft_application_id, on_delete: :cascade
  end

  def down
    with_lock_retries do
      remove_foreign_key :system_access_group_microsoft_graph_access_tokens,
        column: :system_access_group_microsoft_application_id
    end
  end
end
