# frozen_string_literal: true

class ValidateGroupWikiRepositoryStatesGroupWikiRepositoryIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    validate_foreign_key :group_wiki_repository_states, :group_wiki_repository_id, name: :fk_832511c9f1
  end

  def down
    # no-op
  end
end
