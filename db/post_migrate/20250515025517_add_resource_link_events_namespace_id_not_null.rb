# frozen_string_literal: true

class AddResourceLinkEventsNamespaceIdNotNull < Gitlab::Database::Migration[2.3]
  milestone '18.1'
  disable_ddl_transaction!

  def up
    add_not_null_constraint :resource_link_events, :namespace_id
  end

  def down
    remove_not_null_constraint :resource_link_events, :namespace_id
  end
end
