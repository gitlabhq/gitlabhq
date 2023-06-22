# frozen_string_literal: true

class TrackOrganizationDeletions < Gitlab::Database::Migration[2.1]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  enable_lock_retries!

  def up
    # This LFK trigger already exists on some environments and it was reverted
    # in MR: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122809
    track_record_deletions(:organizations) unless has_loose_foreign_key?('organizations')
  end

  def down
    untrack_record_deletions(:organizations)
  end
end
