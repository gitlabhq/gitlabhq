# frozen_string_literal: true

module Banzai
  module Filter
    module References
      class AlertReferenceFilter < IssuableReferenceFilter
        self.reference_type = :alert
        self.object_class   = AlertManagement::Alert

        def object_sym
          :alert
        end

        def parent_records(parent, ids)
          return AlertManagement::Alert.none unless parent.is_a?(Project)

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
end
