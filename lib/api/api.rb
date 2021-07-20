# frozen_string_literal: true

module API
  class API < ::API::Base
    include APIGuard

    LOG_FILENAME = Rails.root.join("log", "api_json.log")

    NO_SLASH_URL_PART_REGEX = %r{[^/]+}.freeze
    NAMESPACE_OR_PROJECT_REQUIREMENTS = { id: NO_SLASH_URL_PART_REGEX }.freeze
    COMMIT_ENDPOINT_REQUIREMENTS = NAMESPACE_OR_PROJECT_REQUIREMENTS.merge(sha: NO_SLASH_URL_PART_REGEX).freeze
    USER_REQUIREMENTS = { user_id: NO_SLASH_URL_PART_REGEX }.freeze
    LOG_FILTERS = ::Rails.application.config.filter_parameters + [/^output$/]

    insert_before Grape::Middleware::Error,
                  GrapeLogging::Middleware::RequestLogger,
                  logger: Logger.new(LOG_FILENAME),
                  formatter: Gitlab::GrapeLogging::Formatters::LogrageWithTimestamp.new,
                  include: [
                    GrapeLogging::Loggers::FilterParameters.new(LOG_FILTERS),
                    Gitlab::GrapeLogging::Loggers::ClientEnvLogger.new,
                    Gitlab::GrapeLogging::Loggers::RouteLogger.new,
                    Gitlab::GrapeLogging::Loggers::UserLogger.new,
                    Gitlab::GrapeLogging::Loggers::ExceptionLogger.new,
                    Gitlab::GrapeLogging::Loggers::QueueDurationLogger.new,
                    Gitlab::GrapeLogging::Loggers::PerfLogger.new,
                    Gitlab::GrapeLogging::Loggers::CorrelationIdLogger.new,
                    Gitlab::GrapeLogging::Loggers::ContextLogger.new,
                    Gitlab::GrapeLogging::Loggers::ContentLogger.new
                  ]

    allow_access_with_scope :api
    allow_access_with_scope :read_api, if: -> (request) { request.get? || request.head? }
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
    end

    before do
      coerce_nil_params_to_array!

      api_endpoint = env['api.endpoint']
      feature_category = api_endpoint.options[:for].try(:feature_category_for_app, api_endpoint).to_s

      Gitlab::ApplicationContext.push(
        user: -> { @current_user },
        project: -> { @project },
        namespace: -> { @group },
        runner: -> { @current_runner || @runner },
        caller_id: api_endpoint.endpoint_id,
        remote_ip: request.ip,
        feature_category: feature_category
      )
    end

    before do
      set_peek_enabled_for_current_request
    end

    after do
      Gitlab::UsageDataCounters::VSCodeExtensionActivityUniqueCounter.track_api_request_when_trackable(user_agent: request&.user_agent, user: @current_user)
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
      error! e.message, e.status, e.headers
    end

    rescue_from Gitlab::Auth::TooManyIps do |e|
      rack_response({ 'message' => '403 Forbidden' }.to_json, 403)
    end

    rescue_from :all do |exception|
      handle_api_exception(exception)
    end

    # This is a specific exception raised by `rack-timeout` gem when Puma
    # requests surpass its timeout. Given it inherits from Exception, we
    # should rescue it separately. For more info, see:
    # - https://github.com/sharpstone/rack-timeout/blob/master/doc/exceptions.md
    # - https://github.com/ruby-grape/grape#exception-handling
    rescue_from Rack::Timeout::RequestTimeoutException do |exception|
      handle_api_exception(exception)
    end

    format :json
    formatter :json, Gitlab::Json::GrapeFormatter
    content_type :json, 'application/json'

    # Ensure the namespace is right, otherwise we might load Grape::API::Helpers
    helpers ::API::Helpers
    helpers ::API::Helpers::CommonHelpers
    helpers ::API::Helpers::PerformanceBarHelpers

    namespace do
      after do
        ::Users::ActivityService.new(@current_user).execute
      end

      # Keep in alphabetical order
      mount ::API::AccessRequests
      mount ::API::Admin::Ci::Variables
      mount ::API::Admin::InstanceClusters
      mount ::API::Admin::PlanLimits
      mount ::API::Admin::Sidekiq
      mount ::API::Appearance
      mount ::API::Applications
      mount ::API::Avatar
      mount ::API::AwardEmoji
      mount ::API::Badges
      mount ::API::Boards
      mount ::API::Branches
      mount ::API::BroadcastMessages
      mount ::API::BulkImports
      mount ::API::Ci::Pipelines
      mount ::API::Ci::PipelineSchedules
      mount ::API::Ci::Runner
      mount ::API::Ci::Runners
      mount ::API::Commits
      mount ::API::CommitStatuses
      mount ::API::ContainerRegistryEvent
      mount ::API::ContainerRepositories
      mount ::API::DependencyProxy
      mount ::API::DeployKeys
      mount ::API::DeployTokens
      mount ::API::Deployments
      mount ::API::Environments
      mount ::API::ErrorTracking
      mount ::API::ErrorTrackingCollector
      mount ::API::Events
      mount ::API::FeatureFlags
      mount ::API::FeatureFlagsUserLists
      mount ::API::Features
      mount ::API::Files
      mount ::API::FreezePeriods
      mount ::API::Geo
      mount ::API::GroupAvatar
      mount ::API::GroupBoards
      mount ::API::GroupClusters
      mount ::API::GroupExport
      mount ::API::GroupImport
      mount ::API::GroupLabels
      mount ::API::GroupMilestones
      mount ::API::Groups
      mount ::API::GroupContainerRepositories
      mount ::API::GroupVariables
      mount ::API::ImportBitbucketServer
      mount ::API::ImportGithub
      mount ::API::IssueLinks
      mount ::API::Invitations
      mount ::API::Issues
      mount ::API::JobArtifacts
      mount ::API::Jobs
      mount ::API::Keys
      mount ::API::Labels
      mount ::API::Lint
      mount ::API::Markdown
      mount ::API::Members
      mount ::API::MergeRequestDiffs
      mount ::API::MergeRequests
      mount ::API::MergeRequestApprovals
      mount ::API::Metrics::Dashboard::Annotations
      mount ::API::Metrics::UserStarredDashboards
      mount ::API::Namespaces
      mount ::API::Notes
      mount ::API::Discussions
      mount ::API::ResourceLabelEvents
      mount ::API::ResourceMilestoneEvents
      mount ::API::ResourceStateEvents
      mount ::API::NotificationSettings
      mount ::API::ProjectPackages
      mount ::API::GroupPackages
      mount ::API::PackageFiles
      mount ::API::NugetProjectPackages
      mount ::API::NugetGroupPackages
      mount ::API::PypiPackages
      mount ::API::ComposerPackages
      mount ::API::ConanProjectPackages
      mount ::API::ConanInstancePackages
      mount ::API::DebianGroupPackages
      mount ::API::DebianProjectPackages
      mount ::API::MavenPackages
      mount ::API::NpmProjectPackages
      mount ::API::NpmInstancePackages
      mount ::API::GenericPackages
      mount ::API::GoProxy
      mount ::API::HelmPackages
      mount ::API::Pages
      mount ::API::PagesDomains
      mount ::API::ProjectClusters
      mount ::API::ProjectContainerRepositories
      mount ::API::ProjectDebianDistributions
      mount ::API::ProjectEvents
      mount ::API::ProjectExport
      mount ::API::ProjectImport
      mount ::API::ProjectHooks
      mount ::API::ProjectMilestones
      mount ::API::ProjectRepositoryStorageMoves
      mount ::API::Projects
      mount ::API::ProjectSnapshots
      mount ::API::ProjectSnippets
      mount ::API::ProjectStatistics
      mount ::API::ProjectTemplates
      mount ::API::Terraform::State
      mount ::API::Terraform::StateVersion
      mount ::API::Terraform::Modules::V1::Packages
      mount ::API::PersonalAccessTokens
      mount ::API::ProtectedBranches
      mount ::API::ProtectedTags
      mount ::API::Releases
      mount ::API::Release::Links
      mount ::API::RemoteMirrors
      mount ::API::Repositories
      mount ::API::ResourceAccessTokens
      mount ::API::RubygemPackages
      mount ::API::Search
      mount ::API::Services
      mount ::API::Settings
      mount ::API::SidekiqMetrics
      mount ::API::SnippetRepositoryStorageMoves
      mount ::API::Snippets
      mount ::API::Statistics
      mount ::API::Submodules
      mount ::API::Subscriptions
      mount ::API::Suggestions
      mount ::API::SystemHooks
      mount ::API::Tags
      mount ::API::Templates
      mount ::API::Todos
      mount ::API::Triggers
      mount ::API::Unleash
      mount ::API::UsageData
      mount ::API::UsageDataQueries
      mount ::API::UsageDataNonSqlMetrics
      mount ::API::UserCounts
      mount ::API::Users
      mount ::API::Variables
      mount ::API::Version
      mount ::API::Wikis
    end

    mount ::API::Internal::Base
    mount ::API::Internal::Lfs
    mount ::API::Internal::Pages
    mount ::API::Internal::Kubernetes

    version 'v3', using: :path do
      # Although the following endpoints are kept behind V3 namespace,
      # they're not deprecated neither should be removed when V3 get
      # removed.  They're needed as a layer to integrate with Jira
      # Development Panel.
      namespace '/', requirements: ::API::V3::Github::ENDPOINT_REQUIREMENTS do
        mount ::API::V3::Github
      end
    end

    route :any, '*path', feature_category: :not_owned do
      error!('404 Not Found', 404)
    end
  end
end

API::API.prepend_mod
