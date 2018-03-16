module EE
  module Gitlab
    module ExternalAuthorization
      module Config
        extend self

        def timeout
          application_settings.external_authorization_service_timeout
        end

        def service_url
          application_settings.external_authorization_service_url
        end

        def enabled?
          application_settings.external_authorization_service_enabled?
        end

        def perform_check?
          enabled? && service_url.present?
        end

        def client_cert
          application_settings.external_auth_client_cert
        end

        def client_key
          application_settings.external_auth_client_key
        end

        def client_key_pass
          application_settings.external_auth_client_key_pass
        end

        def has_tls?
          client_cert.present? && client_key.present?
        end

        private

        def application_settings
          ::Gitlab::CurrentSettings.current_application_settings
        end
      end
    end
  end
end
