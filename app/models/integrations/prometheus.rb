# frozen_string_literal: true

module Integrations
  class Prometheus < Integration
    include Base::Monitoring
    include PrometheusAdapter
    include Gitlab::Utils::StrongMemoize

    field :manual_configuration,
      type: :checkbox,
      title: -> { s_('PrometheusService|Active') },
      help: -> { s_('PrometheusService|Select this checkbox to override the auto configuration settings with your own settings.') },
      required: true

    field :api_url,
      title: 'API URL',
      placeholder: -> { s_('PrometheusService|https://prometheus.example.com/') },
      help: -> { s_('PrometheusService|The Prometheus API base URL.') },
      required: false

    field :google_iap_audience_client_id,
      title: 'Google IAP Audience Client ID',
      placeholder: -> { s_('PrometheusService|IAP_CLIENT_ID.apps.googleusercontent.com') },
      help: -> { s_('PrometheusService|The ID of the IAP-secured resource.') },
      required: false

    field :google_iap_service_account_json,
      type: :textarea,
      title: 'Google IAP Service Account JSON',
      placeholder: -> { s_('PrometheusService|{ "type": "service_account", "project_id": ... }') },
      help: -> { s_('PrometheusService|The contents of the credentials.json file of your service account.') },
      required: false

    # Since the internal Prometheus instance is usually a localhost URL, we need
    # to allow localhost URLs when the following conditions are true:
    # 1. api_url is the internal Prometheus URL.
    with_options presence: true do
      validates :api_url, public_url: true, if: ->(object) { object.api_url.present? && object.manual_configuration? && !object.allow_local_api_url? }
      validates :api_url, url: true, if: ->(object) { object.api_url.present? && object.manual_configuration? && object.allow_local_api_url? }
    end

    before_save :synchronize_service_state

    after_save :clear_reactive_cache!
    after_commit :sync_http_integration!

    after_commit :track_events

    scope :preload_project, -> { preload(:project) }

    override :manual_activation?
    def manual_activation?
      false
    end

    def self.title
      'Prometheus'
    end

    def self.description
      s_('PrometheusService|Monitor application health with Prometheus metrics and dashboards')
    end

    def self.to_param
      'prometheus'
    end

    # Check we can connect to the Prometheus API
    def test(*args)
      return { success: false, result: 'Prometheus configuration error' } unless prometheus_client

      prometheus_client.ping
      { success: true, result: 'Checked API endpoint' }
    rescue Gitlab::PrometheusClient::Error => e
      { success: false, result: e }
    end

    def prometheus_client
      return unless should_return_client?

      options = prometheus_client_default_options.merge(
        allow_local_requests: allow_local_api_url?
      )

      if behind_iap? && iap_client
        # Adds the Authorization header
        options[:headers] = iap_client.apply({})
      end

      Gitlab::PrometheusClient.new(api_url, options)
    end

    def prometheus_available?
      return false unless project

      project.all_clusters.enabled.eager_load(:integration_prometheus).any? do |cluster|
        cluster.integration_prometheus_available?
      end
    end

    def allow_local_api_url?
      allow_local_requests_from_web_hooks_and_services? || internal_prometheus_url?
    end

    def configured?
      should_return_client?
    end

    alias_method :google_iap_service_account_json_raw, :google_iap_service_account_json
    private :google_iap_service_account_json_raw

    MASKED_VALUE = '*' * 8

    def google_iap_service_account_json
      json = google_iap_service_account_json_raw
      return json unless json.present?

      Gitlab::Json.parse(json)
        .then { |hash| hash.transform_values { MASKED_VALUE } }
        .then { |hash| Gitlab::Json.generate(hash) }
    rescue Gitlab::Json.parser_error
      json
    end

    private

    delegate :allow_local_requests_from_web_hooks_and_services?, to: :current_settings, private: true

    def internal_prometheus_url?
      api_url.present? && api_url == ::Gitlab::Prometheus::Internal.uri
    end

    def should_return_client?
      api_url.present? && manual_configuration? && active? && valid?
    end

    def current_settings
      Gitlab::CurrentSettings.current_application_settings
    end

    def synchronize_service_state
      self.active = prometheus_available? || manual_configuration?

      true
    end

    def track_events
      if enabled_manual_prometheus?
        Gitlab::Tracking.event('cluster:services:prometheus', 'enabled_manual_prometheus')
      elsif disabled_manual_prometheus?
        Gitlab::Tracking.event('cluster:services:prometheus', 'disabled_manual_prometheus')
      end

      true
    end

    def enabled_manual_prometheus?
      manual_configuration_changed? && manual_configuration?
    end

    def disabled_manual_prometheus?
      manual_configuration_changed? && !manual_configuration?
    end

    def behind_iap?
      manual_configuration? && google_iap_audience_client_id.present? && google_iap_service_account_json.present?
    end

    def clean_google_iap_service_account
      json = google_iap_service_account_json_raw
      return unless json.present?

      Gitlab::Json.parse(json).except('token_credential_uri')
    rescue Gitlab::Json.parser_error
      {}
    end

    def iap_client
      @iap_client ||= Google::Auth::Credentials
        .new(clean_google_iap_service_account, target_audience: google_iap_audience_client_id)
        .client
    rescue StandardError
      nil
    end
    strong_memoize_attr :iap_client

    # Remove in next required stop after %16.4
    # https://gitlab.com/gitlab-org/gitlab/-/issues/338838
    def sync_http_integration!
      return unless manual_configuration_changed? && !manual_configuration_was.nil?

      project.alert_management_http_integrations
        .for_endpoint_identifier('legacy-prometheus')
        .take
        &.update_columns(active: manual_configuration)
    end
  end
end
