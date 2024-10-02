# frozen_string_literal: true

class LockDuoFeaturesEnabledUpdate < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  TABLE_NAME = :namespace_settings

  def up
    execute <<-SQL.squish
      UPDATE #{TABLE_NAME}
      SET lock_duo_features_enabled = false
      WHERE duo_features_enabled = true AND lock_duo_features_enabled = true
    SQL
  end

  def down
    # no-op. We can't update all records `where(duo_features_enabled: true, lock_duo_features_enabled: false)`
    # because some of them may have been pre-existing.
  end
end
