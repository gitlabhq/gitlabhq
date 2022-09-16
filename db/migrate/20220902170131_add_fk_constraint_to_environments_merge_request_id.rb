# frozen_string_literal: true

class AddFkConstraintToEnvironmentsMergeRequestId < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_concurrent_foreign_key :environments, :merge_requests, column: :merge_request_id, on_delete: :nullify
  end

  def down
    remove_foreign_key_if_exists :environments, column: :merge_request_id
  end
end
