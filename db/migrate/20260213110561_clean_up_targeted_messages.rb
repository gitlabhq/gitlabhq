# frozen_string_literal: true

class CleanUpTargetedMessages < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main_cell_setting
  milestone '18.9'

  def up
    # Clean up existing targeted messages before adding NOT NULL columns.
    # This ensures zero-downtime upgrades for all environments. Since targeted_messages
    # is feature-flagged and new, this will almost certainly be a no-op in production,
    # but we handle it explicitly to avoid migration failures if any data exists.
    # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/216492#note_2971414784
    execute('DELETE FROM targeted_messages')
  end

  def down
    # No-op: data deletion cannot be reversed
  end
end
