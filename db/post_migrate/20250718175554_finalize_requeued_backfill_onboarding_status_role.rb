# frozen_string_literal: true

class FinalizeRequeuedBackfillOnboardingStatusRole < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def up
    # no-op because migration code removed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201015
  end

  def down; end
end
