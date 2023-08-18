# frozen_string_literal: true

# Turning this migration to a no-op due to incident https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16102
# Migration will be retried in 20230801150214_retry_cleanup_bigint_conversion_for_events_for_gitlab_com.rb
class CleanupBigintConversionForEventsForGitlabCom < Gitlab::Database::Migration[2.1]
  def up
    # no-op
  end

  def down
    # no-op
  end
end
