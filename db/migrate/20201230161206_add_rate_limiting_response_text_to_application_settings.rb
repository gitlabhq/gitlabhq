# frozen_string_literal: true

class AddRateLimitingResponseTextToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20210101110640_set_limit_for_rate_limiting_response_text
  def change
    add_column :application_settings, :rate_limiting_response_text, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
