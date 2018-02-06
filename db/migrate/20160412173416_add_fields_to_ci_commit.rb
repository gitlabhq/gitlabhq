# rubocop:disable all
class AddFieldsToCiCommit < ActiveRecord::Migration
  def change
    add_column :ci_commits, :status, :string
    add_column :ci_commits, :started_at, :timestamp
    add_column :ci_commits, :finished_at, :timestamp
    add_column :ci_commits, :duration, :integer
  end
end
