# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RequeuePendingBuilds < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'
  end

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # We're not inserting any data so we don't need to start a transaction.
  disable_ddl_transaction!

  def up
    relation = Build.where(status: 'pending').select(:id)

    relation.find_in_batches(batch_size: 100) do |rows|
      args = rows.map { |row| [row.id] }

      Sidekiq::Client.push_bulk('class' => 'BuildQueueWorker', 'args' => args)
    end
  end

  def down
  end
end
