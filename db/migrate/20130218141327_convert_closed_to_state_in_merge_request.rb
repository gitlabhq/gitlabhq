# rubocop:disable all
class ConvertClosedToStateInMergeRequest < ActiveRecord::Migration
  include Gitlab::Database

  def up
    execute "UPDATE #{table_name} SET state = 'merged' WHERE closed = #{true_value} AND merged = #{true_value}"
    execute "UPDATE #{table_name} SET state = 'closed' WHERE closed = #{true_value} AND merged = #{false_value}"
    execute "UPDATE #{table_name} SET state = 'opened' WHERE closed = #{false_value}"
  end

  def down
    execute "UPDATE #{table_name} SET closed = #{true_value} WHERE state = 'closed'"
    execute "UPDATE #{table_name} SET closed = #{true_value}, merged = #{true_value} WHERE state = 'merged'"
  end

  private

  def table_name
    MergeRequest.table_name
  end
end
