# frozen_string_literal: true

class AddProjectToTimelogs < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :timelogs, :project_id, :integer
    end
  end

  def down
    with_lock_retries do
      remove_column :timelogs, :project_id
    end
  end
end
