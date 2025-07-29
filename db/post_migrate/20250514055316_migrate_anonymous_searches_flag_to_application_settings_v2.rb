# frozen_string_literal: true

class MigrateAnonymousSearchesFlagToApplicationSettingsV2 < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '18.1'

  def up
    # Marking migration as no-op, after required stop.
  end

  def down
    # Marking migration as no-op, after required stop.
  end
end
