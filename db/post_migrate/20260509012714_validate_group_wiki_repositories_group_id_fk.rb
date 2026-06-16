# frozen_string_literal: true

class ValidateGroupWikiRepositoriesGroupIdFk < Gitlab::Database::Migration[2.3]
  milestone '19.1'

  def up
    validate_foreign_key :group_wiki_repositories, :group_id, name: :fk_26f867598c
  end

  def down
    # no-op
  end
end
