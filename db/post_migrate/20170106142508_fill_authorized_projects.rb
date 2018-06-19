# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class FillAuthorizedProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  class User < ApplicationRecord
    self.table_name = 'users'
  end

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # We're not inserting any data so we don't need to start a transaction.
  disable_ddl_transaction!

  def up
    relation = User.select(:id)
      .where('authorized_projects_populated IS NOT TRUE')

    relation.find_in_batches(batch_size: 1_000) do |rows|
      args = rows.map { |row| [row.id] }

      Sidekiq::Client.push_bulk('class' => 'AuthorizedProjectsWorker', 'args' => args)
    end
  end

  def down
  end
end
