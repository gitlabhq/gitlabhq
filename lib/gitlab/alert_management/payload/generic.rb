# frozen_string_literal: true

# Attribute mapping for alerts via generic alerting integration.
module Gitlab
  module AlertManagement
    module Payload
      class Generic < Base
        DEFAULT_TITLE = 'New: Alert'
        DEFAULT_SOURCE = 'Generic Alert Endpoint'

        attribute :description, paths: 'description'
        attribute :ends_at, paths: 'end_time', type: :time_with_epoch_millis
        attribute :environment_name, paths: 'gitlab_environment_name'
        attribute :hosts, paths: 'hosts'
        attribute :monitoring_tool, paths: 'monitoring_tool'
        attribute :runbook, paths: 'runbook'
        attribute :service, paths: 'service'
        attribute :starts_at, paths: 'start_time', type: :time, fallback: -> { Time.current.utc }
        attribute :title, paths: 'title', fallback: -> { DEFAULT_TITLE }

        attribute :severity_raw, paths: 'severity'
        private :severity_raw

        attribute :plain_gitlab_fingerprint, paths: 'fingerprint'
        private :plain_gitlab_fingerprint

        def resolved?
          ends_at.present?
        end

        def source
          super || DEFAULT_SOURCE
        end
      end
    end
  end
end

Gitlab::AlertManagement::Payload::Generic.prepend_mod_with('Gitlab::AlertManagement::Payload::Generic')
