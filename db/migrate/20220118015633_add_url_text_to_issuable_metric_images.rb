# frozen_string_literal: true

class AddUrlTextToIssuableMetricImages < Gitlab::Database::Migration[1.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220118020026_add_url_text_limit_to_issuable_metric_images
  def change
    add_column :issuable_metric_images, :url_text, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
