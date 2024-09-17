# frozen_string_literal: true

class AddLfkTriggersToIssues < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.4'

  def up
    track_record_deletions(:issues)
  end

  def down
    untrack_record_deletions(:issues)
  end
end
