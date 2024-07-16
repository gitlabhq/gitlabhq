# frozen_string_literal: true

class AddGroupIdToRelatedEpicLinks < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :related_epic_links, :group_id, :bigint
  end
end
