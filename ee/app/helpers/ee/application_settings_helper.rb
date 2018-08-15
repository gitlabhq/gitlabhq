module EE
  module ApplicationSettingsHelper
    extend ::Gitlab::Utils::Override

    def external_authorization_description
      _("If enabled, access to projects will be validated on an external service"\
        " using their classification label.")
    end

    def external_authorization_timeout_help_text
      _("Time in seconds GitLab will wait for a response from the external "\
        "service. When the service does not respond in time, access will be "\
        "denied.")
    end

    def external_authorization_url_help_text
      _("When leaving the URL blank, classification labels can still be "\
        "specified without disabling cross project features or performing "\
        "external authorization checks.")
    end

    def external_authorization_client_certificate_help_text
      _("The X509 Certificate to use when mutual TLS is required to communicate "\
        "with the external authorization service. If left blank, the server "\
        "certificate is still validated when accessing over HTTPS.")
    end

    def external_authorization_client_key_help_text
      _("The private key to use when a client certificate is provided. This value "\
        "is encrypted at rest.")
    end

    def external_authorization_client_pass_help_text
      _("The passphrase required to decrypt the private key. This is optional "\
        "and the value is encrypted at rest.")
    end

    def pseudonymizer_enabled_help_text
      _("Enable Pseudonymizer data collection")
    end

    def pseudonymizer_description_text
      _("GitLab will run a background job that will produce pseudonymized CSVs of the GitLab database that will be uploaded to your configured object storage directory.")
    end

    def pseudonymizer_disabled_description_text
      _("The pseudonymizer data collection is disabled. When enabled, GitLab will run a background job that will produce pseudonymized CSVs of the GitLab database that will be uploaded to your configured object storage directory.")
    end

    override :visible_attributes
    def visible_attributes
      super + [
        :allow_group_owners_to_manage_ldap,
        :check_namespace_plan,
        :elasticsearch_aws,
        :elasticsearch_aws_access_key,
        :elasticsearch_aws_region,
        :elasticsearch_aws_secret_access_key,
        :elasticsearch_experimental_indexer,
        :elasticsearch_indexing,
        :elasticsearch_search,
        :elasticsearch_url,
        :geo_status_timeout,
        :help_text,
        :pseudonymizer_enabled,
        :repository_size_limit,
        :shared_runners_minutes,
        :slack_app_enabled,
        :slack_app_id,
        :slack_app_secret,
        :slack_app_verification_token,
        :snowplow_collector_uri,
        :snowplow_cookie_domain,
        :snowplow_enabled,
        :snowplow_site_id
      ]
    end

    def self.repository_mirror_attributes
      [
        :mirror_max_capacity,
        :mirror_max_delay,
        :mirror_capacity_threshold
      ]
    end

    def self.external_authorization_service_attributes
      [
        :external_auth_client_cert,
        :external_auth_client_key,
        :external_auth_client_key_pass,
        :external_authorization_service_default_label,
        :external_authorization_service_enabled,
        :external_authorization_service_timeout,
        :external_authorization_service_url
      ]
    end

    def self.possible_licensed_attributes
      repository_mirror_attributes + external_authorization_service_attributes + %i[
        email_additional_text
        file_template_project_id
      ]
    end
  end
end
