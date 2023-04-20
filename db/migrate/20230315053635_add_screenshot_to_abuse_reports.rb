# frozen_string_literal: true

class AddScreenshotToAbuseReports < Gitlab::Database::Migration[2.1]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20230327074932_add_text_limit_to_abuse_reports_screenshot
  def change
    add_column :abuse_reports, :screenshot, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
