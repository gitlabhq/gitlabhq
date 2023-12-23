# frozen_string_literal: true

class ChangeICodeReviewCreateMrKeysFromRedisHllToRedis < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  def up
    # no-op
    #
    # Removed due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17321
  end

  def down
    # no-op
  end
end
