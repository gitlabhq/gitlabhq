# frozen_string_literal: true

class AddUrlTextLimitToIssuableMetricImages < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :issuable_metric_images, :url_text, 128
  end

  def down
    remove_text_limit :issuable_metric_images, :url_text
  end
end
