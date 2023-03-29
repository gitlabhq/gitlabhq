# frozen_string_literal: true

class AddTextLimitToAbuseReportsScreenshot < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :abuse_reports, :screenshot, 255
  end

  def down
    remove_text_limit :abuse_reports, :screenshot
  end
end
