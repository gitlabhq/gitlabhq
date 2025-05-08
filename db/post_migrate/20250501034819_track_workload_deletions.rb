# frozen_string_literal: true

class TrackWorkloadDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.0'

  def up
    track_record_deletions_override_table_name(:p_ci_workloads)
  end

  def down
    untrack_record_deletions(:p_ci_workloads)
  end
end
