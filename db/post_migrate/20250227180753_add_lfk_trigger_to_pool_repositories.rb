# frozen_string_literal: true

class AddLfkTriggerToPoolRepositories < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.11'

  def up
    track_record_deletions(:pool_repositories)
  end

  def down
    untrack_record_deletions(:pool_repositories)
  end
end
