module API
  class API < Grape::API
    include APIGuard

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
      mount ::API::V3::LdapGroupLinks
      mount ::API::V3::Members
      mount ::API::V3::MergeRequestDiffs
      mount ::API::V3::MergeRequests
      mount ::API::V3::Notes
      mount ::API::V3::Pipelines
      mount ::API::V3::ProjectGitHook
      mount ::API::V3::ProjectPushRule
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

    before { header['X-Frame-Options'] = 'SAMEORIGIN' }
    before { Gitlab::I18n.locale = current_user&.preferred_language }

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
    mount ::API::AwardEmoji
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
    mount ::API::Groups
    mount ::API::Geo
    mount ::API::Internal
    mount ::API::Issues
    mount ::API::IssueLinks
    mount ::API::Jobs
    mount ::API::Keys
    mount ::API::Labels
    mount ::API::Ldap
    mount ::API::LdapGroupLinks
    mount ::API::License
    mount ::API::Lint
    mount ::API::Members
    mount ::API::MergeRequestDiffs
    mount ::API::MergeRequests
    mount ::API::ProjectMilestones
    mount ::API::GroupMilestones
    mount ::API::Namespaces
    mount ::API::Notes
    mount ::API::NotificationSettings
    mount ::API::Pipelines
    mount ::API::PipelineSchedules
    mount ::API::ProjectHooks
    mount ::API::ProjectPushRule
    mount ::API::Projects
    mount ::API::ProjectSnippets
    mount ::API::Repositories
    mount ::API::Runner
    mount ::API::Runners
    mount ::API::Services
    mount ::API::Session
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
    mount ::API::Version

    route :any, '*path' do
      error!('404 Not Found', 404)
    end
  end
end
