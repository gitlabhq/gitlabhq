# rubocop:disable all
class ConvertClosedToStateInMilestone < ActiveRecord::Migration
  include Gitlab::Database

  def up
    execute "UPDATE #{table_name} SET state = 'closed' WHERE closed = #{true_value}"
    execute "UPDATE #{table_name} SET state = 'active' WHERE closed = #{false_value}"
  end

  def down
    execute "UPDATE #{table_name} SET closed = #{true_value} WHERE state = 'cloesd'"
  end

  private

  def table_name
    Milestone.table_name
  end
end
