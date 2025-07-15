# frozen_string_literal: true

class QueueBackfillRolledUpWeightForWorkItems < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op due to https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/27076
  end

  def down
    # no-op
  end
end
