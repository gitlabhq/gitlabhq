# frozen_string_literal: true

class AddGroupIdToGroupWikiRepositoryStates < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :group_wiki_repository_states, :group_id, :bigint
  end
end
