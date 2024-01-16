# frozen_string_literal: true

class ValidateForeignKeyCiJobArtifactState < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  # We first need to introduce this FK for self-managed
  def up
    # no-op
  end

  def down
    # Can be safely a no-op if we don't roll back the inconsistent data.
  end
end
