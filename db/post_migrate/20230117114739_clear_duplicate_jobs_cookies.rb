# frozen_string_literal: true

# This is workaround for
# https://gitlab.com/gitlab-org/gitlab/-/issues/388253. During a
# zero-downtime upgrade, duplicate jobs cookies can fail to get deleted.
# This post-deployment migration deletes all such cookies. This can
# cause some jobs that normally would have been deduplicated to twice
# instead of once.
class ClearDuplicateJobsCookies < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    Gitlab::Redis::Queues.with do |redis| # rubocop:disable Cop/RedisQueueUsage
      redis.scan_each(match: "resque:gitlab:duplicate:*:cookie:v2").each_slice(100) do |keys|
        redis.del(keys)
      end
    end
  end

  def down; end
end
