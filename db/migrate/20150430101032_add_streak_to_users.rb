class AddStreakToUsers < ActiveRecord::Migration
  def change
    add_column :users, :longest_streak_start_at, :date
    add_column :users, :longest_streak_end_at, :date
    add_column :users, :current_streak, :integer, default: 0
    add_column :users, :last_contributed_at, :date
  end
end
