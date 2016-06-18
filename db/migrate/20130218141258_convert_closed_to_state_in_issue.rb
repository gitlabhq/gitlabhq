# rubocop:disable all
class ConvertClosedToStateInIssue < ActiveRecord::Migration
  include Gitlab::Database

  def up
    execute "UPDATE #{table_name} SET state = 'closed' WHERE closed = #{true_value}"
    execute "UPDATE #{table_name} SET state = 'opened' WHERE closed = #{false_value}"
  end

  def down
    execute "UPDATE #{table_name} SET closed = #{true_value} WHERE state = 'closed'"
  end

  private

  def table_name
    Issue.table_name
  end
end
