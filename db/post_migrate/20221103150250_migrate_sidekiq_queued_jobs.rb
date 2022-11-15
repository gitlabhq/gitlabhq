# frozen_string_literal: true

class MigrateSidekiqQueuedJobs < Gitlab::Database::Migration[2.0]
  def up
    # no-op because of https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/1991
  end

  def down
    # no-op
  end
end
