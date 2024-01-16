# frozen_string_literal: true

class DisableFastupdateOnIssueSearchData < Gitlab::Database::Migration[2.2]
  milestone '16.8'

  disable_ddl_transaction!

  NUM_PARTITIONS = 64

  def up
    each_index_name do |index_name|
      with_lock_retries do
        execute <<~SQL
          ALTER INDEX #{index_name} SET ( fastupdate = false ) ;
        SQL
      end
    end
  end

  def down
    each_index_name do |index_name|
      with_lock_retries do
        execute <<~SQL
          ALTER INDEX #{index_name} RESET ( fastupdate ) ;
        SQL
      end
    end
  end

  private

  def each_index_name
    NUM_PARTITIONS.times do |partition|
      yield "gitlab_partitions_static.issue_search_data_#{format('%02d', partition)}_search_vector_idx"
    end
  end
end
