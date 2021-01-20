# frozen_string_literal: true

class AddDevopsAdoptionSnapshotNotNull < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    with_lock_retries do
      execute(
        <<~SQL
          LOCK TABLE analytics_devops_adoption_snapshots IN ACCESS EXCLUSIVE MODE;

          UPDATE analytics_devops_adoption_snapshots SET end_time = date_trunc('month', recorded_at) - interval '1 millisecond';

          ALTER TABLE analytics_devops_adoption_snapshots ALTER COLUMN end_time SET NOT NULL;
      SQL
      )
    end
  end

  def down
    with_lock_retries do
      execute(<<~SQL)
        ALTER TABLE analytics_devops_adoption_snapshots ALTER COLUMN end_time DROP NOT NULL;
      SQL
    end
  end
end
