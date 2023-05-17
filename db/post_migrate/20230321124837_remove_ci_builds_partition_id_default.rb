# frozen_string_literal: true

class RemoveCiBuildsPartitionIdDefault < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def up
    # no-op. See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8588 for details.
  end

  def down
    # no-op. See https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8588 for details.
  end
end
