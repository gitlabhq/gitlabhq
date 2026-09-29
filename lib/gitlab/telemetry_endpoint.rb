# frozen_string_literal: true

module Gitlab
  # Where GitLab's telemetry clients report to. Service Ping and the version
  # check both address the Versions Application today, but they are separate
  # integrations whose destinations need not be the same host, so each reads
  # its own variable.
  #
  # An environment with no request router in front of the Versions
  # Application, such as a local Kubernetes cluster, has no other way to
  # address the two separately.
  module TelemetryEndpoint
    SERVICE_PING_ENV_VAR = 'GITLAB_SERVICE_PING_URL'

    PRODUCTION_URL = 'https://version.gitlab.com'
    STAGING_URL = 'https://gitlab-org-gitlab-services-version-gitlab-com-staging.version-staging.gitlab.org'

    class << self
      def service_ping_url
        return default_url if override_forbidden?

        override(SERVICE_PING_ENV_VAR) || default_url
      end

      # See https://gitlab.com/gitlab-org/gitlab/-/issues/233615 for details
      def default_url
        Rails.env.production? ? PRODUCTION_URL : STAGING_URL
      end

      # Runs from an initializer, so it must not read the licence, and so the
      # database. Rails.env is available, so the message is only hedged where
      # the licence can actually refuse the override.
      def log_configuration
        log_override(SERVICE_PING_ENV_VAR, service_ping_consequence)
      end

      private

      def service_ping_consequence
        return 'Service Ping is sent there' unless Rails.env.production?

        'Service Ping may be sent there, unless the licence requires it'
      end

      # A licence that obliges this instance to report Service Ping must not be
      # circumvented by pointing the report somewhere else.
      #
      # Only production can satisfy that obligation, because every other
      # environment defaults to the staging Versions Application. Refusing the
      # override outside production would send the report somewhere that does
      # not count either, and take a developer's local Versions Application
      # with it. Ordered so that the licence, and so the database, is not read
      # outside production.
      def override_forbidden?
        Rails.env.production? && ServicePing::ServicePingSettings.license_operational_metric_enabled?
      end

      def log_override(env_var, consequence)
        value = ENV[env_var].presence
        return unless value

        origin = override(env_var)

        if origin
          Gitlab::AppLogger.warn(
            message: "#{env_var} is set to #{origin}: #{consequence}, instead of #{default_url}.",
            telemetry_endpoint_env_var: env_var,
            telemetry_endpoint_url: origin
          )
        else
          Gitlab::AppLogger.error(
            message: "#{env_var} is ignored: it must be an absolute http(s) origin with no path, " \
              "query or fragment. The default destination is used instead.",
            telemetry_endpoint_env_var: env_var,
            telemetry_endpoint_url: value
          )
        end
      end

      def override(env_var)
        parse(ENV[env_var])
      end

      # Callers join paths onto the origin, so a path, query or fragment would
      # be silently dropped. Treat such a value as absent rather than guess.
      #
      # Never raises: ServicePing::SubmitService reaches this from its own
      # error handler, so raising would come back a second time from inside
      # the rescue and take the error-reporting path down with the payload.
      def parse(value)
        value = value.to_s.strip
        return if value.empty?

        uri = URI.parse(value)
        return unless uri.is_a?(URI::HTTP) && uri.host.present?
        return unless uri.path.delete_suffix('/').empty? && uri.query.nil? && uri.fragment.nil?

        value.delete_suffix('/')
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
