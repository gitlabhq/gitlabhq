# frozen_string_literal: true

module API
  class API < ::API::Base
    include APIGuard
    include Helpers::OpenApi

    LOG_FILENAME = Rails.root.join("log", "api_json.log")

    NO_SLASH_URL_PART_REGEX = %r{[^/]+}
    NAMESPACE_OR_PROJECT_REQUIREMENTS = { id: NO_SLASH_URL_PART_REGEX }.freeze
    COMMIT_ENDPOINT_REQUIREMENTS = NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(sha: NO_SLASH_URL_PART_REGEX).freeze
    USER_REQUIREMENTS = { user_id: NO_SLASH_URL_PART_REGEX }.freeze
    LOG_FILTERS = ::Rails.application.config.filter_parameters + [/^output$/]
    LOG_FORMATTER = Gitlab::GrapeLogging::Formatters::LogrageWithTimestamp.new
    LOGGER = Logger.new(LOG_FILENAME, level: ::Gitlab::Utils.to_rails_log_level(ENV["GITLAB_LOG_LEVEL"], :info))

    class MovedPermanentlyError < StandardError
      MSG_PREFIX = 'This resource has been moved permanently to'

      attr_reader :location_url

      def initialize(location_url)
        @location_url = location_url

        super("#{MSG_PREFIX} #{location_url}")
      end
    end

    insert_before Grape::Middleware::Error,
      GrapeLogging::Middleware::RequestLogger,
      logger: LOGGER,
      formatter: LOG_FORMATTER,
      include: [
        Gitlab::GrapeLogging::Loggers::FilterParameters.new(LOG_FILTERS),
        Gitlab::GrapeLogging::Loggers::ClientEnvLogger.new,
        Gitlab::GrapeLogging::Loggers::RouteLogger.new,
        Gitlab::GrapeLogging::Loggers::UserLogger.new,
        Gitlab::GrapeLogging::Loggers::TokenLogger.new,
        Gitlab::GrapeLogging::Loggers::ExceptionLogger.new,
        Gitlab::GrapeLogging::Loggers::QueueDurationLogger.new,
        Gitlab::GrapeLogging::Loggers::PerfLogger.new,
        Gitlab::GrapeLogging::Loggers::CorrelationIdLogger.new,
        Gitlab::GrapeLogging::Loggers::ContextLogger.new,
        Gitlab::GrapeLogging::Loggers::ContentLogger.new,
        Gitlab::GrapeLogging::Loggers::UrgencyLogger.new,
        Gitlab::GrapeLogging::Loggers::ResponseLogger.new
      ]

    allow_access_with_scope :api
    allow_access_with_scope :read_api, if: ->(request) { request.get? || request.head? }
    prefix :api

    version 'v3', using: :path do
      route :any, '*path' do
        error!('API V3 is no longer supported. Use API V4 instead.', 410)
      end
    end

    version 'v4', using: :path

    before do
      header['X-Frame-Options'] = 'SAMEORIGIN'
      header['X-Content-Type-Options'] = 'nosniff'

      if Rails.application.config.content_security_policy && !Rails.application.config.content_security_policy_report_only
        policy = ActionDispatch::ContentSecurityPolicy.new { |p| p.default_src :none }
      end

      request.env[ActionDispatch::ContentSecurityPolicy::Request::POLICY] = policy
    end

    before do
      coerce_nil_params_to_array!

      api_endpoint = request.env[Grape::Env::API_ENDPOINT]
      feature_category = api_endpoint.options[:for].try(:feature_category_for_app, api_endpoint).to_s

      # remote_ip is added here and the ContextLogger so that the
      # client_id field is set correctly, as the user object does not
      # survive between multiple context pushes.
      Gitlab::ApplicationContext.push(
        user: -> { @current_user },
        project: -> { @project },
        namespace: -> { @group },
        runner: -> { @current_runner || @runner },
        remote_ip: request.ip,
        caller_id: api_endpoint.endpoint_id,
        feature_category: feature_category,
        **http_router_rule_context
      )

      increment_http_router_metrics
    end

    before do
      set_peek_enabled_for_current_request
    end

    after do
      Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter.track_api_request_when_trackable(user_agent: request&.user_agent, user: @current_user)
    end

    after do
      Gitlab::UsageDataCounters::JetBrainsPluginActivityUniqueCounter.track_api_request_when_trackable(user_agent: request&.user_agent, user: @current_user)
    end

    after do
      Gitlab::UsageDataCounters::JetBrainsBundledPluginActivityUniqueCounter.track_api_request_when_trackable(user_agent: request&.user_agent, user: @current_user)
    end

    after do
      Gitlab::UsageDataCounters::VisualStudioExtensionActivityUniqueCounter.track_api_request_when_trackable(user_agent: request&.user_agent, user: @current_user)
    end

    after do
      Gitlab::UsageDataCounters::NeovimPluginActivityUniqueCounter.track_api_request_when_trackable(user_agent: request&.user_agent, user: @current_user)
    end

    after do
      Gitlab::UsageDataCounters::GitLabCliActivityUniqueCounter.track_api_request_when_trackable(user_agent: request&.user_agent, user: @current_user)
    end

    # The locale is set to the current user's locale when `current_user` is loaded
    after { Gitlab::I18n.use_default_locale }

    rescue_from Gitlab::Access::AccessDeniedError do
      rack_response({ 'message' => '403 Forbidden' }.to_json, 403)
    end

    rescue_from ActiveRecord::RecordNotFound do
      rack_response({ 'message' => '404 Not found' }.to_json, 404)
    end

    rescue_from(
      ::ActiveRecord::StaleObjectError,
      ::Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
    ) do
      rack_response({ 'message' => '409 Conflict: Resource lock' }.to_json, 409)
    end

    rescue_from UploadedFile::InvalidPathError do |e|
      rack_response({ 'message' => e.message }.to_json, 400)
    end

    rescue_from ObjectStorage::RemoteStoreError do |e|
      rack_response({ 'message' => e.message }.to_json, 500)
    end

    # Retain 405 error rather than a 500 error for Grape 0.15.0+.
    # https://github.com/ruby-grape/grape/blob/a3a28f5b5dfbb2797442e006dbffd750b27f2a76/UPGRADING.md#changes-to-method-not-allowed-routes
    rescue_from Grape::Exceptions::MethodNotAllowed do |e|
      error! e.message, e.status, e.headers
    end

    rescue_from Grape::Exceptions::Base do |e|
      error!(e.message, e.status, e.headers || {})
    end

    rescue_from MovedPermanentlyError do |e|
      rack_response(e.message, 301, { 'Location' => e.location_url })
    end

    rescue_from Gitlab::Auth::TooManyIps do |e|
      rack_response({ 'message' => '403 Forbidden' }.to_json, 403)
    end

    rescue_from Gitlab::Git::ResourceExhaustedError do |exception|
      rack_response({ 'message' => exception.message }.to_json, 503, exception.headers)
    end

    rescue_from :all do |exception|
      handle_api_exception(exception)
    end

    # This is a specific exception raised by `rack-timeout` gem when Puma
    # requests surpass its timeout. Given it inherits from Exception, we
    # should rescue it separately. For more info, see:
    # - https://github.com/zombocom/rack-timeout/blob/master/doc/exceptions.md
    # - https://github.com/ruby-grape/grape#exception-handling
    rescue_from Rack::Timeout::RequestTimeoutException do |exception|
      handle_api_exception(exception)
    end

    rescue_from RateLimitedService::RateLimitedError do |exception|
      exception.log_request(context.request, context.current_user)
      rack_response({ 'message' => { 'error' => exception.message } }.to_json, 429, exception.headers)
    end

    format :json
    formatter :json, Gitlab::Json::GrapeFormatter
    content_type :json, 'application/json'

    # Ensure the namespace is right, otherwise we might load Grape::API::Helpers
    helpers ::API::Helpers
    helpers ::API::Helpers::CommonHelpers
    helpers ::API::Helpers::PerformanceBarHelpers
    helpers ::API::Helpers::RateLimiter
    helpers Gitlab::HttpRouter::RuleContext
    helpers Gitlab::HttpRouter::RuleMetrics

    namespace do
      after do
        ::Users::ActivityService.new(author: @current_user, project: @project, namespace: @group).execute
      end

      # Mount endpoints to include in the OpenAPI V2 documentation here
      namespace do
        # Keep in alphabetical order
        mount ::API::AccessRequests
        mount ::API::Admin::BatchedBackgroundMigrations
        mount ::API::Admin::BroadcastMessages
        mount ::API::Admin::Ci::Variables
        mount ::API::Admin::Dictionary
        mount ::API::Admin::InstanceClusters
        mount ::API::Admin::Migrations
        mount ::API::Admin::PlanLimits
        mount ::API::Admin::Token
        mount ::API::AlertManagementAlerts
        mount ::API::Appearance
        mount ::API::Applications
        mount ::API::Avatar
        mount ::API::Badges
        mount ::API::Branches
        mount ::API::BulkImports
        mount ::API::Ci::Catalog
        mount ::API::Ci::JobArtifacts
        mount ::API::Groups
        mount ::API::Ci::Jobs
        mount ::API::Ci::ResourceGroups
        mount ::API::Ci::Runner
        mount ::API::Ci::Runners
        mount ::API::Ci::SecureFiles
        mount ::API::Ci::Pipelines
        mount ::API::Ci::PipelineSchedules
        mount ::API::Ci::Triggers
        mount ::API::Ci::Variables
        mount ::API::ClusterDiscovery
        mount ::API::Clusters::AgentTokens
        mount ::API::Clusters::Agents
        mount ::API::Commits
        mount ::API::CommitStatuses
        mount ::API::ComposerPackages
        mount ::API::Conan::V1::InstancePackages
        mount ::API::Conan::V1::ProjectPackages
        mount ::API::Conan::V2::ProjectPackages
        mount ::API::ContainerRegistryEvent
        mount ::API::ContainerRepositories
        mount ::API::DebianGroupPackages
        mount ::API::DebianProjectPackages
        mount ::API::DependencyProxy
        mount ::API::DeployKeys
        mount ::API::DeployTokens
        mount ::API::Deployments
        mount ::API::DraftNotes
        mount ::API::Environments
        mount ::API::ErrorTracking::ClientKeys
        mount ::API::ErrorTracking::ProjectSettings
        mount ::API::Events
        mount ::API::FeatureFlags
        mount ::API::FeatureFlagsUserLists
        mount ::API::Features
        mount ::API::Files
        mount ::API::FreezePeriods
        mount ::API::GenericPackages
        mount ::API::Geo
        mount ::API::GoProxy
        mount ::API::GroupAvatar
        mount ::API::GroupClusters
        mount ::API::GroupContainerRepositories
        mount ::API::GroupDebianDistributions
        mount ::API::GroupExport
        mount ::API::GroupImport
        mount ::API::GroupPackages
        mount ::API::GroupVariables
        mount ::API::HelmPackages
        mount ::API::ImportBitbucket
        mount ::API::ImportBitbucketServer
        mount ::API::ImportGithub
        mount ::API::Integrations
        mount ::API::Integrations::Slack::Events
        mount ::API::Integrations::Slack::Interactions
        mount ::API::Integrations::Slack::Options
        mount ::API::Integrations::JiraConnect::Subscriptions
        mount ::API::Invitations
        mount ::API::IssueLinks
        mount ::API::Keys
        mount ::API::Lint
        mount ::API::Markdown
        mount ::API::MarkdownUploads
        mount ::API::MavenPackages
        mount ::API::Members
        mount ::API::MergeRequestApprovals
        mount ::API::MergeRequests
        mount ::API::MergeRequestDiffs
        mount ::API::Metadata
        mount ::API::MlModelPackages
        mount ::API::Namespaces
        mount ::API::NpmGroupPackages
        mount ::API::NpmInstancePackages
        mount ::API::NpmProjectPackages
        mount ::API::NugetGroupPackages
        mount ::API::NugetProjectPackages
        mount ::API::Organizations
        mount ::API::PackageFiles
        mount ::API::Pages
        mount ::API::PagesDomains
        mount ::API::PersonalAccessTokens::SelfInformation
        mount ::API::PersonalAccessTokens::SelfRotation
        mount ::API::PersonalAccessTokens
        mount ::API::ProjectAvatar
        mount ::API::ProjectClusters
        mount ::API::ProjectContainerRepositories
        mount ::API::ProjectContainerRegistryProtectionRules
        mount ::API::ProjectDebianDistributions
        mount ::API::ProjectEvents
        mount ::API::ProjectExport
        mount ::API::ProjectHooks
        mount ::API::ProjectImport
        mount ::API::ProjectJobTokenScope
        mount ::API::ProjectPackages
        mount ::API::ProjectPackagesProtectionRules
        mount ::API::ProjectRepositoryStorageMoves
        mount ::API::ProjectSnapshots
        mount ::API::ProjectSnippets
        mount ::API::ProjectStatistics
        mount ::API::ProjectTemplates
        mount ::API::Projects
        mount ::API::ProtectedBranches
        mount ::API::ProtectedTags
        mount ::API::PypiPackages
        mount ::API::Releases
        mount ::API::Release::Links
        mount ::API::RemoteMirrors
        mount ::API::Repositories
        mount ::API::ResourceAccessTokens::SelfRotation
        mount ::API::ResourceAccessTokens
        mount ::API::ResourceMilestoneEvents
        mount ::API::RpmProjectPackages
        mount ::API::RubygemPackages
        mount ::API::Snippets
        mount ::API::SnippetRepositoryStorageMoves
        mount ::API::Statistics
        mount ::API::Submodules
        mount ::API::Suggestions
        mount ::API::SystemHooks
        mount ::API::Tags
        mount ::API::Terraform::Modules::V1::NamespacePackages
        mount ::API::Terraform::Modules::V1::ProjectPackages
        mount ::API::Terraform::State
        mount ::API::Terraform::StateVersion
        mount ::API::Topics
        mount ::API::Unleash
        mount ::API::UsageData
        mount ::API::UsageDataServicePing
        mount ::API::UsageDataTrack
        mount ::API::UsageDataNonSqlMetrics
        mount ::API::UsageDataQueries
        mount ::API::Users
        mount ::API::UserCounts
        mount ::API::UserRunners
        mount ::API::VirtualRegistries::Packages::Maven::Registries
        mount ::API::VirtualRegistries::Packages::Maven::Upstreams
        mount ::API::VirtualRegistries::Packages::Maven::Cache::Entries
        mount ::API::VirtualRegistries::Packages::Maven::Endpoints
        mount ::API::WebCommits
        mount ::API::Wikis

        add_open_api_documentation!
      end

      # Keep in alphabetical order
      mount ::API::Admin::Sidekiq
      mount ::API::AwardEmoji
      mount ::API::Boards
      mount ::API::Ci::Pipelines
      mount ::API::Ci::PipelineSchedules
      mount ::API::Ci::SecureFiles
      mount ::API::Discussions
      mount ::API::GroupBoards
      mount ::API::GroupLabels
      mount ::API::GroupMilestones
      mount ::API::Issues
      mount ::API::Labels
      mount ::API::Notes
      mount ::API::NotificationSettings
      mount ::API::ProjectEvents
      mount ::API::ProjectMilestones
      mount ::API::ProtectedTags
      mount ::API::ResourceLabelEvents
      mount ::API::ResourceStateEvents
      mount ::API::Search
      mount ::API::Settings
      mount ::API::SidekiqMetrics
      mount ::API::Subscriptions
      mount ::API::Tags
      mount ::API::Templates
      mount ::API::Todos
      mount ::API::UsageData
      mount ::API::UsageDataServicePing
      mount ::API::UsageDataTrack
      mount ::API::UsageDataNonSqlMetrics
      mount ::API::VsCode::Settings::VsCodeSettingsSync
      mount ::API::Ml::Mlflow::Entrypoint
      mount ::API::Ml::MlflowArtifacts::Entrypoint
    end

    mount ::API::Internal::AutoFlow
    mount ::API::Internal::Base
    mount ::API::Internal::Coverage if Gitlab::Utils.to_boolean(ENV['COVERBAND_ENABLED'], default: false)
    mount ::API::Internal::Lfs
    mount ::API::Internal::Pages
    mount ::API::Internal::Kubernetes
    mount ::API::Internal::ErrorTracking
    mount ::API::Internal::MailRoom
    mount ::API::Internal::Workhorse
    mount ::API::Internal::Shellhorse

    route :any, '*path', feature_category: :not_owned do
      error!('404 Not Found', 404)
    end
  end
end

API::API.prepend_mod
