# frozen_string_literal: true

class FinalizeBackfillOnboardingStatusRole < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def up
    # no-op because migration code removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201015
  end

  def down; end
end
