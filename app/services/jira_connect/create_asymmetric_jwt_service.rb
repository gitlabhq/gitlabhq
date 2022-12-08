# frozen_string_literal: true

module JiraConnect
  class CreateAsymmetricJwtService
    ARGUMENT_ERROR_MESSAGE = 'jira_connect_installation is not a proxy installation'

    def initialize(jira_connect_installation, event: :installed)
      raise ArgumentError, ARGUMENT_ERROR_MESSAGE unless jira_connect_installation.proxy?

      @jira_connect_installation = jira_connect_installation
      @event = event
    end

    def execute
      JWT.encode(jwt_claims, private_key, 'RS256', jwt_headers)
    end

    private

    def jwt_claims
      { aud: aud_claim, iss: iss_claim, qsh: qsh_claim }
    end

    def aud_claim
      @jira_connect_installation.audience_url
    end

    def iss_claim
      @jira_connect_installation.client_key
    end

    def qsh_claim
      Atlassian::Jwt.create_query_string_hash(
        audience_event_url,
        'POST',
        @jira_connect_installation.audience_url
      )
    end

    def audience_event_url
      return @jira_connect_installation.audience_uninstalled_event_url if @event == :uninstalled

      @jira_connect_installation.audience_installed_event_url
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.generate(3072)
    end

    def public_key_storage
      @public_key_storage ||= JiraConnect::PublicKey.create!(key: private_key.public_key)
    end

    def jwt_headers
      { kid: public_key_storage.uuid }
    end
  end
end
