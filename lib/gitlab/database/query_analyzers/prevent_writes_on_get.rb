# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      # Logs data-modifying queries served during HTTP GET and HEAD requests
      class PreventWritesOnGet < Base
        # exclude_context! keeps the formatter from evaluating the lazy Labkit
        # context mid-request, which would memoize attributes like meta.user
        # before the controller assigns them
        class Logger < ::Gitlab::JsonLogger
          exclude_context!

          def self.file_name_noext
            'database_writes_on_get'
          end
        end

        MONITORED_REQUEST_METHODS = %w[GET HEAD].freeze

        WRITE_REGEX = /\b(?:INSERT|UPDATE|DELETE|MERGE)\b/i

        IGNORED_TABLES = %w[schema_migrations ar_internal_metadata plans gitlab_subscriptions].freeze

        TRACKING_URL = 'https://gitlab.com/gitlab-org/gitlab/-/issues/608670'

        EXCLUDE_FROM_TRACE = %w[
          lib/gitlab/database/query_analyzer.rb
          lib/gitlab/database/query_analyzers/prevent_writes_on_get.rb
        ].freeze

        ALLOWED_ENDPOINTS = {
          'Projects::MergeRequestsController#show' => TRACKING_URL,
          'Projects::MergeRequestsController#diffs' => TRACKING_URL,
          'Projects::MergeRequestsController#discussions' => TRACKING_URL,
          'Projects::MergeRequestsController#reports' => TRACKING_URL,
          'Projects::MergeRequestsController#license_scanning_reports_collapsed' => TRACKING_URL,
          'Projects::MergeRequests::ConflictsController#show' => TRACKING_URL,
          'Projects::MergeRequests::ContentController#widget' => TRACKING_URL,
          'Projects::MergeRequests::CreationsController#new' => TRACKING_URL,
          'Projects::AutocompleteSourcesController#commands' => TRACKING_URL,
          'Projects::AutocompleteSourcesController#members' => TRACKING_URL,
          'GET /api/:version/projects/:id/merge_requests' => TRACKING_URL,
          'GET /api/:version/projects/:id/merge_requests/:merge_request_iid' => TRACKING_URL,
          'GET /api/:version/projects/:id/merge_requests/:merge_request_iid/changes' => TRACKING_URL,

          'Projects::RepositoriesController#archive' => TRACKING_URL,
          'GET /api/:version/projects/:id/repository/archive' => TRACKING_URL,
          'GET /api/:version/internal/orbit/project/:project_id/repository/archive' => TRACKING_URL,
          'GET /api/:version/projects/:id/packages/composer/archives/*package_name' => TRACKING_URL,

          'Groups::DependencyProxyForContainersController#manifest' => TRACKING_URL,
          'Groups::DependencyProxyForContainersController#blob' => TRACKING_URL,
          'GET /api/:version/projects/:id/dependency_proxy/packages/maven/*path/:file_name' => TRACKING_URL,
          'GET /api/:version/projects/:id/dependency_proxy/packages/npm/*package_name/-/*file_name' => TRACKING_URL,
          'GET /api/:version/virtual_registries/packages/maven/:id/*path' => TRACKING_URL,

          'Projects::BoardsController#show' => TRACKING_URL,
          'Projects::BoardsController#index' => TRACKING_URL,
          'Groups::BoardsController#show' => TRACKING_URL,
          'Groups::BoardsController#index' => TRACKING_URL,

          'Projects::Settings::RepositoryController#show' => TRACKING_URL,
          'Groups::Settings::RepositoryController#show' => TRACKING_URL,

          'OmniauthCallbacksController#google_oauth2' => TRACKING_URL,
          'OmniauthCallbacksController#github' => TRACKING_URL,
          'OmniauthCallbacksController#auth0' => TRACKING_URL,
          'OmniauthCallbacksController#openid_connect' => TRACKING_URL,
          'OmniauthCallbacksController#salesforce' => TRACKING_URL,
          'OmniauthCallbacksController#gitlab' => TRACKING_URL,
          'OmniauthCallbacksController#bitbucket' => TRACKING_URL,
          'OmniauthCallbacksController#alicloud' => TRACKING_URL,
          'OmniauthCallbacksController#jwt' => TRACKING_URL,
          'OmniauthCallbacksController#saml' => TRACKING_URL,
          'Groups::OmniauthCallbacksController#group_saml' => TRACKING_URL,
          'InvitesController#show' => TRACKING_URL,
          'InvitesController#decline' => TRACKING_URL,
          'GET /api/:version/ai/duo_workflows/ws' => TRACKING_URL,
          'ConfirmationsController#show' => TRACKING_URL,
          'Devise::UnlocksController#show' => TRACKING_URL,
          'Registrations::WelcomeController#show' => TRACKING_URL,
          'UserSettings::PasswordsController#new' => TRACKING_URL,
          'Users::RegistrationsIdentityVerificationController#success' => TRACKING_URL,
          'Users::RegistrationsIdentityVerificationController#verify_credit_card' => TRACKING_URL,
          'Users::IdentityVerificationController#verify_credit_card' => TRACKING_URL,
          'Profiles::TwoFactorAuthsController#show' => TRACKING_URL,
          'Profiles::PasskeysController#new' => TRACKING_URL,
          'Iam::ConsentController#show' => TRACKING_URL,
          'Oauth::AuthorizationsController#new' => TRACKING_URL,

          'JwtController#auth' => TRACKING_URL,
          'Projects::Registry::RepositoriesController#index' => TRACKING_URL,

          'GET /api/:version/internal/kubernetes/verify_project_access' => TRACKING_URL,
          'GET /api/:version/internal/kubernetes/modules/remote_development/prerequisites' => TRACKING_URL,
          'GET /api/:version/internal/kubernetes/modules/starboard_vulnerability/policies_configuration' =>
            TRACKING_URL,
          'GET /api/:version/internal/agents/agentk/agent_info' => TRACKING_URL,
          'GET /api/:version/internal/ci/agents/runnerc/info' => TRACKING_URL,

          'IdeController#index' => TRACKING_URL,
          'Projects::Security::VulnerabilityReportController#index' => TRACKING_URL,
          'Projects::Security::DashboardController#index' => TRACKING_URL,
          'Groups::Analytics::CycleAnalyticsController#show' => TRACKING_URL,

          'Repositories::GitHttpController#info_refs' => TRACKING_URL,
          'Projects::FeatureFlagsController#index' => TRACKING_URL,
          'Groups::SecretsController#index' => TRACKING_URL,
          'Groups::RoadmapController#show' => TRACKING_URL,
          'GET /api/:version/projects/:id/pipelines/:pipeline_id/test_report' => TRACKING_URL,
          'GET /api/:version/license/usage_export' => TRACKING_URL
        }.freeze

        class << self
          def allow_write_on_get(url:, &blk) # rubocop:disable Lint/UnusedMethodArgument -- url documents the tracking issue
            with_suppressed(true, &blk)
          end

          def enabled?
            MONITORED_REQUEST_METHODS.include?(::Gitlab::Middleware::QueryAnalyzer.http_request_method) &&
              ::Feature::FlipperFeature.table_exists? &&
              Feature.enabled?(:detect_writes_on_get, Feature.current_request, type: :ops)
          end

          def analyze(parsed)
            return unless WRITE_REGEX.match?(parsed.raw)
            return unless parsed.pg

            tables = write_tables(parsed)
            return if tables.empty?

            caller_id = ::Gitlab::ApplicationContext.current_context_attribute(:caller_id)
            return if allowed_endpoint?(caller_id)

            log_violation(parsed, tables, caller_id)
          end

          private

          def write_tables(parsed)
            tables = parsed.sql.downcase.include?(' for update') ? parsed.pg.tables : parsed.pg.dml_tables

            tables - IGNORED_TABLES
          end

          def allowed_endpoint?(caller_id)
            ALLOWED_ENDPOINTS.key?(caller_id)
          end

          def log_violation(parsed, tables, caller_id)
            Logger.warn(
              message: 'write_on_get_detected',
              caller_id: caller_id,
              request_method: request_method,
              tables: tables,
              sql: parsed.sql,
              stacktrace: backtrace.first(5)
            )
          end

          def request_method
            ::Gitlab::Middleware::QueryAnalyzer.http_request_method
          end

          def backtrace
            Gitlab::BacktraceCleaner.clean_backtrace(caller).reject do |line|
              EXCLUDE_FROM_TRACE.any? { |exclusion| line.include?(exclusion) }
            end
          end
        end
      end
    end
  end
end
