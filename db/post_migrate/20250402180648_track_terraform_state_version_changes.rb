# frozen_string_literal: true

class TrackTerraformStateVersionChanges < Gitlab::Database::Migration[2.2]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '17.11'

  def up
    track_record_deletions(:terraform_state_versions)
  end

  def down
    untrack_record_deletions(:terraform_state_versions)
  end
end
