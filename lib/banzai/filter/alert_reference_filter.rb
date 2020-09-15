# frozen_string_literal: true

module Banzai
  module Filter
    class AlertReferenceFilter < IssuableReferenceFilter
      self.reference_type = :alert

      def self.object_class
        AlertManagement::Alert
      end

      def self.object_sym
        :alert
      end

      def parent_records(parent, ids)
        parent.alert_management_alerts.where(iid: ids.to_a)
      end

      def url_for_object(alert, project)
        ::Gitlab::Routing.url_helpers.details_project_alert_management_url(
          project,
          alert.iid,
          only_path: context[:only_path]
        )
      end
    end
  end
end
