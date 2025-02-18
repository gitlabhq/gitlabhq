# frozen_string_literal: true

class ValidateWorkItemParentLinksNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def up
    validate_not_null_constraint :work_item_parent_links, :namespace_id
  end

  def down
    # no-op
  end
end
