# frozen_string_literal: true

class RemovePaJitsuRelatedSettings < Gitlab::Database::Migration[2.1]
  def up
    # Changed to a no-op, this migration was reverted after
    # an incident during a deploy to staging.gitlab.com
    # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16274
  end

  def down
    # no-op
  end
end
