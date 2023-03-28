# frozen_string_literal: true

class BackfillProductAnalyticsDataCollectorHost < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # fills product_analytics_data_collector_host by replacing jitsu_host subdomain with collector
    regex = "'://(.+?\\.)'"
    replace_with = "'://collector.'"
    execute <<~SQL
      UPDATE application_settings
      SET product_analytics_data_collector_host = regexp_replace(jitsu_host, #{regex}, #{replace_with}, 'g')
      WHERE jitsu_host IS NOT NULL AND product_analytics_data_collector_host IS NULL
    SQL
  end

  def down
    #   noop
  end
end
