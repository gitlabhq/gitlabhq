# frozen_string_literal: true

class AddOtelAndMcpUrlsToObservabilityGroupO11ySettings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :observability_group_o11y_settings, :o11y_otel_url, :text, if_not_exists: true
      add_column :observability_group_o11y_settings, :o11y_mcp_url, :text, if_not_exists: true
    end

    add_text_limit :observability_group_o11y_settings, :o11y_otel_url, 255
    add_text_limit :observability_group_o11y_settings, :o11y_mcp_url, 255
  end

  def down
    remove_column :observability_group_o11y_settings, :o11y_otel_url, if_exists: true
    remove_column :observability_group_o11y_settings, :o11y_mcp_url, if_exists: true
  end
end
