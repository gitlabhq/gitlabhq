# frozen_string_literal: true

module Ci
  # The purpose of this class is to store Build related runner session.
  # Data will be removed after transitioning from running to any state.
  class BuildRunnerSession < Ci::ApplicationRecord
    include IgnorableColumns

    ignore_columns :build_id_convert_to_bigint, remove_with: '14.1', remove_after: '2021-07-22'

    TERMINAL_SUBPROTOCOL = 'terminal.gitlab.com'
    DEFAULT_SERVICE_NAME = 'build'
    DEFAULT_PORT_NAME = 'default_port'

    self.table_name = 'ci_builds_runner_session'

    belongs_to :build, class_name: 'Ci::Build', inverse_of: :runner_session

    validates :build, presence: true
    validates :url, addressable_url: { schemes: %w(https) }

    def terminal_specification
      wss_url = Gitlab::UrlHelpers.as_wss(self.url)
      return {} unless wss_url.present?

      wss_url = "#{wss_url}/exec"
      channel_specification(wss_url, TERMINAL_SUBPROTOCOL)
    end

    def service_specification(service: nil, path: nil, port: nil, subprotocols: nil)
      return {} unless url.present?

      port = port.presence || DEFAULT_PORT_NAME
      service = service.presence || DEFAULT_SERVICE_NAME
      url = "#{self.url}/proxy/#{service}/#{port}/#{path}"
      subprotocols = subprotocols.presence || ::Ci::BuildRunnerSession::TERMINAL_SUBPROTOCOL

      channel_specification(url, subprotocols)
    end

    private

    def channel_specification(url, subprotocol)
      return {} if subprotocol.blank? || url.blank?

      {
        subprotocols: Array(subprotocol),
        url: url,
        headers: { Authorization: [authorization.presence] }.compact,
        ca_pem: certificate.presence
      }
    end
  end
end
