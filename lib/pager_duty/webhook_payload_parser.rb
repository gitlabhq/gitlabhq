# frozen_string_literal: true

module PagerDuty
  class WebhookPayloadParser
    SCHEMA_PATH = Rails.root.join('lib', 'pager_duty', 'validator', 'schemas', 'message.json')

    def initialize(payload)
      @payload = payload
    end

    def self.call(payload)
      new(payload).call
    end

    def call
      parse_message(payload)
    end

    private

    attr_reader :payload

    def parse_message(message)
      return {} unless valid_message?(message)

      {
        'event' => message.dig('event', 'event_type'),
        'incident' => parse_incident(message.dig('event', 'data'))
      }
    end

    def parse_incident(incident)
      return {} unless incident

      {
        'url' => incident['html_url'],
        'incident_number' => incident['number'],
        'title' => incident['title'],
        'status' => incident['status'],
        'created_at' => incident['created_at'],
        'urgency' => incident['urgency'],
        'incident_key' => incident['incident_key'],
        'assignees' => reject_empty(parse_assignees(incident)),
        'impacted_service' => parse_impacted_service(incident)
      }
    end

    def parse_assignees(incident)
      return [] unless incident

      Array(incident['assignees']).map do |a|
        {
          'summary' => a['summary'],
          'url' => a['html_url']
        }
      end
    end

    def parse_impacted_service(incident)
      return {} unless incident

      return {} if incident.dig('service', 'summary').blank? && incident.dig('service', 'html_url').blank?

      {
        'summary' => incident.dig('service', 'summary'),
        'url' => incident.dig('service', 'html_url')
      }
    end

    def reject_empty(entities)
      Array(entities).reject { |e| e['summary'].blank? && e['url'].blank? }
    end

    def valid_message?(message)
      ::JSONSchemer.schema(SCHEMA_PATH).valid?(message)
    end
  end
end
