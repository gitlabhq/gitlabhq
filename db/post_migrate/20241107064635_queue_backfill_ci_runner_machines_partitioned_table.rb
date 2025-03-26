# frozen_string_literal: true

class QueueBackfillCiRunnerMachinesPartitionedTable < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def up
    # no-op: the backfill on this table is causing issues due to a problem in the timing of the PDMs:
    #
    # 1. db/post_migrate/20241107064635_queue_backfill_ci_runner_machines_partitioned_table.rb
    # 2. db/post_migrate/20241211072300_retry_add_fk_from_partitioned_ci_runner_managers_to_partitioned_ci_runners.rb
    # 3. db/post_migrate/20241219100359_requeue_backfill_ci_runners_partitioned_table.rb
    #
    # Migration #2 installs a FK check before the target table (ci_runners_e59bb2812d) is backfilled (#3), so we
    # have https://gitlab.com/gitlab-org/gitlab/-/issues/520092. We can afford to not backfill
    # ci_runner_machines_687967fa8a, since it'll be populated with runner data automatically as they request jobs from
    # the GitLab instance.
  end

  def down
    # no-op
  end
end
