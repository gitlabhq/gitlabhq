# frozen_string_literal: true

module Ci
  # The purpose of this class is to store Build related runner session.
  # Data will be removed after transitioning from running to any state.
  class BuildRunnerSession < Ci::ApplicationRecord
    include Ci::Partitionable

    TERMINAL_SUBPROTOCOL = 'terminal.gitlab.com'
    DEFAULT_SERVICE_NAME = 'build'
    DEFAULT_PORT_NAME = 'default_port'

    self.table_name = 'ci_builds_runner_session'

    belongs_to :build,
      ->(runner_session) { in_partition(runner_session) },
      class_name: 'Ci::Build',
      partition_foreign_key: :partition_id,
      inverse_of: :runner_session

    partitionable scope: :build

    validates :build, presence: true
    validates :url, public_url: { schemes: %w[https] }

    def terminal_specification
      wss_url = Gitlab::UrlHelpers.as_wss(Addressable::URI.escape(url))
      return {} unless wss_url.present?

      parsed_wss_url = URI.parse(wss_url)
      parsed_wss_url.path += '/exec'
      channel_specification(parsed_wss_url, TERMINAL_SUBPROTOCOL)
    end

    def service_specification(service: nil, path: nil, port: nil, subprotocols: nil)
      return {} unless url.present?

      port = port.presence || DEFAULT_PORT_NAME
      service = service.presence || DEFAULT_SERVICE_NAME
      parsed_url = URI.parse(Addressable::URI.escape(url))
      parsed_url.path += "/proxy/#{service}/#{port}/#{path}"
      subprotocols = subprotocols.presence || ::Ci::BuildRunnerSession::TERMINAL_SUBPROTOCOL

      channel_specification(parsed_url, subprotocols)
    end

    private

    def channel_specification(parsed_url, subprotocol)
      return {} if subprotocol.blank? || parsed_url.blank?

      {
        subprotocols: Array(subprotocol),
        url: Addressable::URI.unescape(parsed_url.to_s),
        headers: { Authorization: [authorization.presence] }.compact,
        ca_pem: certificate.presence
      }
    end
  end
end
