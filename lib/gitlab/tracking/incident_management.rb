# frozen_string_literal: true

module Gitlab
  module Tracking
    module IncidentManagement
      class << self
        def track_from_params(incident_params)
          return if incident_params.blank?

          incident_params.each do |k, v|
            prefix = ['', '0'].include?(v.to_s) ? 'disabled' : 'enabled'

            key = tracking_keys.dig(k, :name)
            label = tracking_keys.dig(k, :label)

            next if key.blank?

            details = label ? { label: label, property: v } : {}

            ::Gitlab::Tracking.event('IncidentManagement::Settings', "#{prefix}_#{key}", **details)
          end
        end

        def tracking_keys
          {
            create_issue: {
              name: 'issue_auto_creation_on_alerts'
            },
            issue_template_key: {
              name: 'issue_template_on_alerts',
              label: 'Template name'
            },
            send_email: {
              name: 'sending_emails'
            },
            pagerduty_active: {
              name: 'pagerduty_webhook'
            },
            auto_close_incident: {
              name: 'auto_close_incident'
            }
          }.with_indifferent_access.freeze
        end
      end
    end
  end
end
