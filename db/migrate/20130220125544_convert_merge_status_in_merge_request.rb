# rubocop:disable all
class ConvertMergeStatusInMergeRequest < ActiveRecord::Migration
  def up
    execute "UPDATE #{table_name} SET new_merge_status = 'unchecked' WHERE merge_status = 1"
    execute "UPDATE #{table_name} SET new_merge_status = 'can_be_merged' WHERE merge_status = 2"
    execute "UPDATE #{table_name} SET new_merge_status = 'cannot_be_merged' WHERE merge_status = 3"
  end

  def down
    execute "UPDATE #{table_name} SET merge_status = 1 WHERE new_merge_status = 'unchecked'"
    execute "UPDATE #{table_name} SET merge_status = 2 WHERE new_merge_status = 'can_be_merged'"
    execute "UPDATE #{table_name} SET merge_status = 3 WHERE new_merge_status = 'cannot_be_merged'"
  end

  private

  def table_name
    MergeRequest.table_name
  end
end
