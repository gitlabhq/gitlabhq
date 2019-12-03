# frozen_string_literal: true

module Gitlab
  class GrafanaEmbedUsageData
    class << self
      def issue_count
        # rubocop:disable CodeReuse/ActiveRecord
        Issue.joins('JOIN grafana_integrations USING (project_id)')
          .where("issues.description LIKE '%' || grafana_integrations.grafana_url || '%'")
          .where(grafana_integrations: { enabled: true })
          .count
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
