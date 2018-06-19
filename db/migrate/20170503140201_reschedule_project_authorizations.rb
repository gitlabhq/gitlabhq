# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RescheduleProjectAuthorizations < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class User < ApplicationRecord
    self.table_name = 'users'
  end

  def up
    offset = 0
    batch = 5000
    start = Time.now

    loop do
      relation = User.where('id > ?', offset)
      user_ids = relation.limit(batch).reorder(id: :asc).pluck(:id)

      break if user_ids.empty?

      offset = user_ids.last

      # This will schedule each batch 5 minutes after the previous batch was
      # scheduled. This smears out the load over time, instead of immediately
      # scheduling a million jobs.
      Sidekiq::Client.push_bulk(
        'queue' => 'authorized_projects',
        'args' => user_ids.zip,
        'class' => 'AuthorizedProjectsWorker',
        'at' => start.to_i
      )

      start += 5.minutes
    end
  end

  def down
  end
end
