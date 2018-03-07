module API
  class API < Grape::API
    include APIGuard

    LOG_FILENAME = Rails.root.join("log", "api_json.log")

    NO_SLASH_URL_PART_REGEX = %r{[^/]+}
    PROJECT_ENDPOINT_REQUIREMENTS = { id: NO_SLASH_URL_PART_REGEX }.freeze
    COMMIT_ENDPOINT_REQUIREMENTS = PROJECT_ENDPOINT_REQUIREMENTS.merge(sha: NO_SLASH_URL_PART_REGEX).freeze

    use GrapeLogging::Middleware::RequestLogger,
        logger: Logger.new(LOG_FILENAME),
        formatter: Gitlab::GrapeLogging::Formatters::LogrageWithTimestamp.new,
        include: [
          GrapeLogging::Loggers::FilterParameters.new,
          GrapeLogging::Loggers::ClientEnv.new,
          Gitlab::GrapeLogging::Loggers::UserLogger.new
        ]

    allow_access_with_scope :api
    prefix :api

    version %w(v3 v4), using: :path

    version 'v3', using: :path do
      helpers ::API::V3::Helpers
      helpers ::API::Helpers::CommonHelpers

      mount ::API::V3::AwardEmoji
      mount ::API::V3::Boards
      mount ::API::V3::Branches
      mount ::API::V3::BroadcastMessages
      mount ::API::V3::Builds
      mount ::API::V3::Commits
      mount ::API::V3::DeployKeys
      mount ::API::V3::Environments
      mount ::API::V3::Files
      mount ::API::V3::Groups
      mount ::API::V3::Issues
      mount ::API::V3::Labels
      mount ::API::V3::Members
      mount ::API::V3::MergeRequestDiffs
      mount ::API::V3::MergeRequests
      mount ::API::V3::Notes
      mount ::API::V3::Pipelines
      mount ::API::V3::ProjectHooks
      mount ::API::V3::Milestones
      mount ::API::V3::Projects
      mount ::API::V3::ProjectSnippets
      mount ::API::V3::Repositories
      mount ::API::V3::Runners
      mount ::API::V3::Services
      mount ::API::V3::Settings
      mount ::API::V3::Snippets
      mount ::API::V3::Subscriptions
      mount ::API::V3::SystemHooks
      mount ::API::V3::Tags
      mount ::API::V3::Templates
      mount ::API::V3::Todos
      mount ::API::V3::Triggers
      mount ::API::V3::Users
      mount ::API::V3::Variables
    end

    before do
      header['X-Frame-Options'] = 'SAMEORIGIN'
      header['X-Content-Type-Options'] = 'nosniff'
    end

    # The locale is set to the current user's locale when `current_user` is loaded
    after { Gitlab::I18n.use_default_locale }

    rescue_from Gitlab::Access::AccessDeniedError do
      rack_response({ 'message' => '403 Forbidden' }.to_json, 403)
    end

    rescue_from ActiveRecord::RecordNotFound do
      rack_response({ 'message' => '404 Not found' }.to_json, 404)
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

    format :json
    content_type :txt, "text/plain"

    # Ensure the namespace is right, otherwise we might load Grape::API::Helpers
    helpers ::SentryHelper
    helpers ::API::Helpers
    helpers ::API::Helpers::CommonHelpers

    # Keep in alphabetical order
    mount ::API::AccessRequests
    mount ::API::Applications
    mount ::API::AwardEmoji
    mount ::API::Badges
    mount ::API::Boards
    mount ::API::Branches
    mount ::API::BroadcastMessages
    mount ::API::CircuitBreakers
    mount ::API::Commits
    mount ::API::CommitStatuses
    mount ::API::DeployKeys
    mount ::API::Deployments
    mount ::API::Environments
    mount ::API::Events
    mount ::API::Features
    mount ::API::Files
    mount ::API::GroupBoards
    mount ::API::Groups
    mount ::API::GroupMilestones
    mount ::API::Internal
    mount ::API::Issues
    mount ::API::Jobs
    mount ::API::JobArtifacts
    mount ::API::Keys
    mount ::API::Labels
    mount ::API::Lint
    mount ::API::Members
    mount ::API::MergeRequestDiffs
    mount ::API::MergeRequests
    mount ::API::Namespaces
    mount ::API::Notes
    mount ::API::Discussions
    mount ::API::NotificationSettings
    mount ::API::PagesDomains
    mount ::API::Pipelines
    mount ::API::PipelineSchedules
    mount ::API::ProjectExport
    mount ::API::ProjectImport
    mount ::API::ProjectHooks
    mount ::API::Projects
    mount ::API::ProjectMilestones
    mount ::API::ProjectSnippets
    mount ::API::ProtectedBranches
    mount ::API::Repositories
    mount ::API::Runner
    mount ::API::Runners
    mount ::API::Search
    mount ::API::Services
    mount ::API::Settings
    mount ::API::SidekiqMetrics
    mount ::API::Snippets
    mount ::API::Subscriptions
    mount ::API::SystemHooks
    mount ::API::Tags
    mount ::API::Templates
    mount ::API::Todos
    mount ::API::Triggers
    mount ::API::Users
    mount ::API::Variables
    mount ::API::GroupVariables
    mount ::API::Version
    mount ::API::Wikis

    route :any, '*path' do
      error!('404 Not Found', 404)
    end
  end
end
