# frozen_string_literal: true

class AddIndexForInProductMarketingEmailMetrics < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_in_product_marketing_emails_on_track_series_id_clicked'

  def up
    add_concurrent_index :in_product_marketing_emails, %i[track series id cta_clicked_at], name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :in_product_marketing_emails, INDEX_NAME
  end
end
