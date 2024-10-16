# frozen_string_literal: true

class AddIssueLinkIdToRelatedEpicLinks < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    add_column :related_epic_links, :issue_link_id, :bigint
  end

  def down
    remove_column :related_epic_links, :issue_link_id, if_exists: true
  end
end
