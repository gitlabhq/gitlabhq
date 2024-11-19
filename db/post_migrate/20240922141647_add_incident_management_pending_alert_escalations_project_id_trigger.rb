# frozen_string_literal: true

class AddIncidentManagementPendingAlertEscalationsProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168212
  end

  def down
    # no-op because there was a bug in the original migration, which has been
    # fixed by https://gitlab.com/gitlab-org/gitlab/-/merge_requests/168212
  end
end
