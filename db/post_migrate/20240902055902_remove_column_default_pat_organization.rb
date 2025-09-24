# frozen_string_literal: true

class RemoveColumnDefaultPatOrganization < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.4'

  def change
    change_column_default(:personal_access_tokens, :organization_id, from: 1, to: nil)
  end
end
