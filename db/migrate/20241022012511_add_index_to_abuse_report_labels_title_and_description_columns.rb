# frozen_string_literal: true

class AddIndexToAbuseReportLabelsTitleAndDescriptionColumns < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.6'

  TITLE_INDEX_NAME = 'index_abuse_report_labels_on_title_trigram'
  DESCRIPTION_INDEX_NAME = 'index_abuse_report_labels_on_description_trigram'

  def up
    add_concurrent_index :abuse_report_labels, :title, name: TITLE_INDEX_NAME,
      using: :gin, opclass: { name: :gin_trgm_ops }
    add_concurrent_index :abuse_report_labels, :description, name: DESCRIPTION_INDEX_NAME,
      using: :gin, opclass: { name: :gin_trgm_ops }
  end

  def down
    remove_concurrent_index_by_name :abuse_report_labels, TITLE_INDEX_NAME
    remove_concurrent_index_by_name :abuse_report_labels, DESCRIPTION_INDEX_NAME
  end
end
