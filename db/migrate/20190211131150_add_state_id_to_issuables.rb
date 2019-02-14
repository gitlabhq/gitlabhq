# frozen_string_literal: true

class AddStateIdToIssuables < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    add_column :issues, :state_id, :integer, limit: 2
    add_column :merge_requests, :state_id, :integer, limit: 2
  end

  def down
    remove_column :issues, :state_id
    remove_column :merge_requests, :state_id
  end
end
