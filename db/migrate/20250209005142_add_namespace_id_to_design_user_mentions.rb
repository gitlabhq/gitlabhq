# frozen_string_literal: true

class AddNamespaceIdToDesignUserMentions < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    add_column :design_user_mentions, :namespace_id, :bigint
  end
end
