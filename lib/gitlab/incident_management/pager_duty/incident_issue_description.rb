# frozen_string_literal: true

module Gitlab
  module IncidentManagement
    module PagerDuty
      class IncidentIssueDescription
        def initialize(incident_payload)
          @incident_payload = incident_payload
        end

        def to_s
          markdown_line_break = "  \n"

          [
            "**Incident:** #{markdown_incident}",
            "**Incident number:** #{incident_payload['incident_number']}",
            "**Urgency:** #{incident_payload['urgency']}",
            "**Status:** #{incident_payload['status']}",
            "**Incident key:** #{incident_payload['incident_key']}",
            "**Created at:** #{markdown_incident_created_at}",
            "**Assignees:** #{markdown_assignees.join(', ')}",
            "**Impacted services:** #{markdown_impacted_services.join(', ')}"
          ].join(markdown_line_break)
        end

        private

        attr_reader :incident_payload

        def markdown_incident
          markdown_link(incident_payload['title'], incident_payload['url'])
        end

        def incident_created_at
          Time.zone.parse(incident_payload['created_at'])
        rescue StandardError
          Time.current.utc # PagerDuty provides time in UTC
        end

        def markdown_incident_created_at
          incident_created_at.strftime('%d %B %Y, %-l:%M%p (%Z)')
        end

        def markdown_assignees
          Array(incident_payload['assignees']).map do |assignee|
            markdown_link(assignee['summary'], assignee['url'])
          end
        end

        def markdown_impacted_services
          Array(incident_payload['impacted_services']).map do |is|
            markdown_link(is['summary'], is['url'])
          end
        end

        def markdown_link(label, url)
          return label if url.blank?

          "[#{label}](#{url})"
        end
      end
    end
  end
end
