# frozen_string_literal: true

class RemoveNotNullConstraintFromWorkItemType < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/85866 introduced a NOT NULL constraint on
  # `issues` which caused QA failures (https://gitlab.com/gitlab-org/gitlab/-/issues/362023), and
  # Helm database issues resulting in broken tests after restoring the database.
  def up
    remove_not_null_constraint :issues, :work_item_type_id, constraint_name: 'check_2addf801cd'
  end

  def down
    add_not_null_constraint :issues, :work_item_type_id, validate: false
  end
end
