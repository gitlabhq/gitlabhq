# frozen_string_literal: true

class AddStatusCategoryAndIdIndexToAbuseReports < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_abuse_reports_on_status_category_and_id'

  disable_ddl_transaction!

  def up
    add_concurrent_index :abuse_reports, [:status, :category, :id], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :abuse_reports, INDEX_NAME
  end
end
