# frozen_string_literal: true

module Gitlab
  module Middleware
    # InternalApiAuthenticator provides authentication support to JsonValidation middleware
    #   - verifies internal API authentication before JSON body parsing occurs
    #   - routes the requests to appropriate verification methods.
    class InternalApiAuthenticator
      INTERNAL_AUTH_ROUTES = [
        {
          description: 'GitLab Subscriptions - CustomersDot',
          patterns: [%r{\A/api/v4/internal/gitlab_subscriptions/}],
          verifier: :verify_subscriptions
        },
        {
          description: 'AppSec::Dast::SiteValidations',
          patterns: [%r{\A/api/v4/internal/dast/}],
          verifier: :verify_dast_job
        },
        {
          description: 'Search::Zoekt',
          patterns: [
            %r{\A/api/v4/internal/search/zoekt/}
          ],
          verifier: :verify_shell
        },
        {
          description: 'Observability',
          patterns: [%r{\A/api/v4/internal/observability/}],
          verifier: :verify_workhorse
        },
        {
          description: 'Secrets Manager',
          patterns: [%r{\A/api/v4/internal/secrets_manager/}],
          verifier: :verify_openbao
        },
        {
          description: 'CI::JobRouter',
          patterns: [%r{\A/api/v4/internal/ci/job_router/}],
          verifier: :verify_kas
        },
        {
          description: 'Internal Base Access',
          patterns: [
            %r{\A/api/v4/internal/(allowed|lfs_authenticate|two_factor|personal_access_token|pre_receive|post_receive)}
          ],
          verifier: :verify_shell
        },
        {
          description: 'Error Tracking Service',
          patterns: [%r{\A/api/v4/internal/error_tracking/}],
          verifier: :verify_error_tracking
        },
        {
          description: 'Kubernetes(KAS)',
          patterns: [%r{\A/api/v4/internal/kubernetes/}],
          verifier: :verify_kas
        },
        {
          description: 'Mail Room',
          patterns: [%r{\A/api/v4/internal/mail_room/}],
          verifier: :verify_mailroom
        },
        {
          description: 'Shellhorse',
          patterns: [%r{\A/api/v4/internal/shellhorse/}],
          verifier: :verify_shell_or_workhorse
        },
        {
          description: 'Workhorse',
          patterns: [%r{\A/api/v4/internal/workhorse/}],
          verifier: :verify_workhorse
        },
        {
          description: 'Coverage(Coverband)',
          patterns: [%r{\A/api/v4/internal/coverage}],
          verifier: :verify_coverage
        }
      ].freeze

      def self.verify!(request)
        new(request).verify!
      end

      def initialize(request)
        @request = request
        @path = request.path.delete_prefix(relative_url)
        @headers = normalize_headers(request.env)
      end

      def verify!
        route_config = INTERNAL_AUTH_ROUTES.find do |config|
          config[:patterns].any? { |pattern| pattern.match?(path) }
        end

        return false.tap { log_auth_failure_info("Invalid route") } unless route_config

        public_send(route_config[:verifier]) # rubocop: disable GitlabSecurity/PublicSend -- No user input
      end

      # Gitlab Subscriptions
      def verify_subscriptions
        !!::GitlabSubscriptions::API::Internal::Auth.verify_api_request(headers)

      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      # Kubernetes
      def verify_kas
        !!::Gitlab::Kas.verify_api_request(headers)
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      # Observability + Workhorse
      def verify_workhorse
        Gitlab::Workhorse.verify_api_request!(headers)
        true
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      # InternalBase/Search Zoekt
      def verify_shell
        !!::Gitlab::Shell.verify_api_request(headers)
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      def verify_shell_or_workhorse
        if ::Gitlab::Shell.header_set?(headers)
          !!::Gitlab::Shell.verify_api_request(headers)
        else
          ::Gitlab::Workhorse.verify_api_request!(headers)
          true
        end
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      # Openbao auth logic - from API::Internal::SecretsManager#openbao_authentication_token_secret
      # TODO - refactor into a helper to be used by api endpoint and here
      def verify_openbao
        token_from_header = headers['Gitlab-Openbao-Auth-Token']
        return false.tap { log_auth_failure_info("Missing auth token") } unless token_from_header.present?

        secret_token = read_openbao_secret_token
        unless secret_token
          return false.tap do
            log_auth_failure_info("Unable to fetch Openbao authentication token secret")
          end
        end

        ::Rack::Utils.secure_compare(token_from_header, secret_token)
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      # Dast::SiteValidations
      def verify_dast_job
        job_token = headers['Job-Token']

        return false.tap { log_auth_failure_info("Missing Job-Token") } unless job_token.present?

        job = ::Ci::AuthJobFinder.new(token: job_token).execute!
        !!job
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      def verify_mailroom
        mailbox_type_match = path.match(%r{\A/api/v4/internal/mail_room/(?<mailbox_type>[^/]+)\z})
        return false.tap { log_auth_failure_info("Missing mailbox type param") } unless mailbox_type_match

        !!::Gitlab::MailRoom::Authenticator.verify_api_request(headers, mailbox_type_match[:mailbox_type])
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      def verify_error_tracking
        token = headers['Gitlab-Error-Tracking-Token']

        token ||= request.GET['error_tracking_token']

        return false.tap { log_auth_failure_info("Missing tracking token") } unless token.present?

        secret = Gitlab::CurrentSettings.error_tracking_access_token
        return false.tap { log_auth_failure_info("Missing secret token") } unless secret

        ::Devise.secure_compare(secret, token.chomp)
      rescue StandardError => e
        log_auth_failure_info(e)
        false
      end

      # API::Internal::Coverage
      def verify_coverage
        # requests to this endpoing should never contain any params or body
        request.env['rack.input'] = StringIO.new('{}')
        true
      end

      private

      attr_reader :request, :path, :headers

      def relative_url
        File.join('', Gitlab.config.gitlab.relative_url_root).chomp('/')
      end

      # This matches the way gems/grape-2.0.0/lib/grape/request.rb#headers works
      # this helper method is used to extract headers for JWT auth for internal apis
      def normalize_headers(env)
        headers = {}

        env.each do |key, value|
          next unless key.start_with?('HTTP_')

          header_name = key[5..].split('_').map(&:capitalize).join('-')
          headers[header_name] = value
        end

        headers['Content-Type'] = env['CONTENT_TYPE'] if env['CONTENT_TYPE']
        headers['Content-Length'] = env['CONTENT_LENGTH'] if env['CONTENT_LENGTH']

        headers
      end

      # Openbao auth logic - from API::Internal::SecretsManager#openbao_authentication_token_secret
      # TODO - refactor into a helper to be used by api endpoint and here
      def read_openbao_secret_token
        file_path = Gitlab.config.openbao['authentication_token_secret_file_path']
        return unless file_path

        real_path = Pathname.new(file_path).realpath.to_s

        allowed_paths = [Rails.root.realpath.to_s + File::SEPARATOR]
        allowed_paths << '/etc/gitlab/' unless Rails.env.development? || Rails.env.test?

        return unless allowed_paths.any? { |allowed| real_path.start_with?(allowed) }
        return unless File.file?(real_path)

        token = File.read(real_path).chomp
        token.presence
      rescue Errno::ENOENT, Errno::EACCES, ArgumentError => e
        Gitlab::ErrorTracking.track_exception(e)
        nil
      end

      def log_auth_failure_info(error)
        Gitlab::AppLogger.info(
          message: "Internal API authentication failed",
          error: error.class.name,
          path: request.path
        )
      end
    end
  end
end
