# frozen_string_literal: true

class AddLabelLinksNamespaceIdNotNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '18.6'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :label_links, :namespace_id
  end

  def down
    remove_not_null_constraint :label_links, :namespace_id
  end
end
