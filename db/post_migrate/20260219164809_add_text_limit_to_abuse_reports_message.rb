# frozen_string_literal: true

class AddTextLimitToAbuseReportsMessage < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.10'

  def up
    add_text_limit :abuse_reports, :message, 2_048, validate: false
  end

  def down
    remove_text_limit :abuse_reports, :message
  end
end
