# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Alert
      extend self

      def build(alert)
        {
          object_kind: 'alert',
          object_attributes: hook_attrs(alert)
        }
      end

      def hook_attrs(alert)
        {
          title: alert.title,
          url: Gitlab::Routing.url_helpers.details_project_alert_management_url(alert.project, alert.iid),
          severity: alert.severity,
          events: alert.events,
          status: alert.status_name,
          started_at: alert.started_at
        }
      end
    end
  end
end
