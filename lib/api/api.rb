# frozen_string_literal: true

module API
  class API < Grape::API
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
                    Gitlab::GrapeLogging::Loggers::CorrelationIdLogger.new
                  ]

    allow_access_with_scope :api
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
      Gitlab::ApplicationContext.push(
        user: -> { current_user },
        project: -> { @project },
        namespace: -> { @group }
      )
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

    format :json
    content_type :txt, "text/plain"

    # Ensure the namespace is right, otherwise we might load Grape::API::Helpers
    helpers ::API::Helpers
    helpers ::API::Helpers::CommonHelpers

    # Keep in alphabetical order
    mount ::API::AccessRequests
    mount ::API::Applications
    mount ::API::Avatar
    mount ::API::AwardEmoji
    mount ::API::Badges
    mount ::API::Boards
    mount ::API::Branches
    mount ::API::BroadcastMessages
    mount ::API::Commits
    mount ::API::CommitStatuses
    mount ::API::DeployKeys
    mount ::API::Deployments
    mount ::API::Environments
    mount ::API::Events
    mount ::API::Features
    mount ::API::Files
    mount ::API::GroupBoards
    mount ::API::GroupClusters
    mount ::API::GroupExport
    mount ::API::GroupLabels
    mount ::API::GroupMilestones
    mount ::API::Groups
    mount ::API::GroupContainerRepositories
    mount ::API::GroupVariables
    mount ::API::ImportGithub
    mount ::API::Internal::Base
    mount ::API::Internal::Pages
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
    mount ::API::Namespaces
    mount ::API::Notes
    mount ::API::Discussions
    mount ::API::ResourceLabelEvents
    mount ::API::NotificationSettings
    mount ::API::Pages
    mount ::API::PagesDomains
    mount ::API::Pipelines
    mount ::API::PipelineSchedules
    mount ::API::ProjectClusters
    mount ::API::ProjectContainerRepositories
    mount ::API::ProjectEvents
    mount ::API::ProjectExport
    mount ::API::ProjectImport
    mount ::API::ProjectHooks
    mount ::API::ProjectMilestones
    mount ::API::Projects
    mount ::API::ProjectSnapshots
    mount ::API::ProjectSnippets
    mount ::API::ProjectStatistics
    mount ::API::ProjectTemplates
    mount ::API::ProtectedBranches
    mount ::API::ProtectedTags
    mount ::API::Releases
    mount ::API::Release::Links
    mount ::API::RemoteMirrors
    mount ::API::Repositories
    mount ::API::Runner
    mount ::API::Runners
    mount ::API::Search
    mount ::API::Services
    mount ::API::Settings
    mount ::API::SidekiqMetrics
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
    mount ::API::UserCounts
    mount ::API::Users
    mount ::API::Variables
    mount ::API::Version
    mount ::API::Wikis

    route :any, '*path' do
      error!('404 Not Found', 404)
    end
  end
end

API::API.prepend_if_ee('::EE::API::API')
