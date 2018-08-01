module Ci
  # The purpose of this class is to store Build related runner session.
  # Data will be removed after transitioning from running to any state.
  class BuildRunnerSession < ActiveRecord::Base
    extend Gitlab::Ci::Model

    self.table_name = 'ci_builds_runner_session'

    belongs_to :build, class_name: 'Ci::Build', inverse_of: :runner_session

    validates :build, presence: true
    validates :url, url: { protocols: %w(https) }

    def terminal_specification
      return {} unless url.present?

      {
        subprotocols: ['terminal.gitlab.com'].freeze,
        url: "#{url}/exec".sub("https://", "wss://"),
        headers: { Authorization: [authorization.presence] }.compact,
        ca_pem: certificate.presence
      }
    end
  end
end
