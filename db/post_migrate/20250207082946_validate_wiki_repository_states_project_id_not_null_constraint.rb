# frozen_string_literal: true

class ValidateWikiRepositoryStatesProjectIdNotNullConstraint < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    validate_not_null_constraint :wiki_repository_states, :project_id
  end

  def down
    # no-op
  end
end
