# frozen_string_literal: true

class AddLinksToSpamToAbuseReports < Gitlab::Database::Migration[2.1]
  def change
    add_column :abuse_reports, :links_to_spam, :text, array: true, null: false, default: []
  end
end
