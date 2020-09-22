# frozen_string_literal: true

# Attribute mapping for alerts via generic alerting integration.
module Gitlab
  module AlertManagement
    module Payload
      class Generic < Base
        DEFAULT_TITLE = 'New: Incident'
        DEFAULT_SEVERITY = 'critical'

        attribute :description, paths: 'description'
        attribute :ends_at, paths: 'end_time', type: :time
        attribute :environment_name, paths: 'gitlab_environment_name'
        attribute :hosts, paths: 'hosts'
        attribute :monitoring_tool, paths: 'monitoring_tool'
        attribute :runbook, paths: 'runbook'
        attribute :service, paths: 'service'
        attribute :severity, paths: 'severity', fallback: -> { DEFAULT_SEVERITY }
        attribute :starts_at, paths: 'start_time', type: :time, fallback: -> { Time.current.utc }
        attribute :title, paths: 'title', fallback: -> { DEFAULT_TITLE }

        attribute :plain_gitlab_fingerprint, paths: 'fingerprint'
        private :plain_gitlab_fingerprint
      end
    end
  end
end

Gitlab::AlertManagement::Payload::Generic.prepend_if_ee('EE::Gitlab::AlertManagement::Payload::Generic')
