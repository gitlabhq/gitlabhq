# frozen_string_literal: true

class ValidateZoektIndexFkChangeOnZoektRepositories < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  NEW_CONSTRAINT_NAME = ChangeZoektIndexFkOnZoektRepositories::NEW_CONSTRAINT_NAME

  # foreign key added in ChangeZoektIndexFkOnZoektRepositories migration
  def up
    validate_foreign_key(:zoekt_repositories, :zoekt_index_id, name: NEW_CONSTRAINT_NAME)
  end

  def down
    # no-op
  end
end
