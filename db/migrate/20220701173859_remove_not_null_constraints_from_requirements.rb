# frozen_string_literal: true

class RemoveNotNullConstraintsFromRequirements < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    change_column_null :requirements, :created_at, true
    change_column_null :requirements, :updated_at, true
    change_column_null :requirements, :title, true
    change_column_null :requirements, :state, true
  end

  def down
    # No OP
    # The columns could have nil values again at this point. Rolling back
    # would cause an exception, also we cannot insert data and modify the schema within the same migration.
    # More details at https://gitlab.com/gitlab-org/gitlab/-/merge_requests/91611#note_1017066470
  end
end
