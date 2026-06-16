# frozen_string_literal: true

class ValidateGroupWikiRepositoryStatesGroupIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    validate_foreign_key :group_wiki_repository_states, :group_id, name: :fk_621768bf3d
  end

  def down
    # no-op
  end
end
