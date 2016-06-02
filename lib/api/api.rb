module API
  class API < Grape::API
    include APIGuard
    version 'v3', using: :path

    rescue_from ActiveRecord::RecordNotFound do
      rack_response({ 'message' => '404 Not found' }.to_json, 404)
    end

    rescue_from :all do |exception|
      # lifted from https://github.com/rails/rails/blob/master/actionpack/lib/action_dispatch/middleware/debug_exceptions.rb#L60
      # why is this not wrapped in something reusable?
      trace = exception.backtrace

      message = "\n#{exception.class} (#{exception.message}):\n"
      message << exception.annoted_source_code.to_s if exception.respond_to?(:annoted_source_code)
      message << "  " << trace.join("\n  ")

      API.logger.add Logger::FATAL, message
      rack_response({ 'message' => '500 Internal Server Error' }.to_json, 500)
    end

    format :json
    content_type :txt, "text/plain"

    # Ensure the namespace is right, otherwise we might load Grape::API::Helpers
    helpers ::API::Helpers

    mount ::API::Geo
    mount ::API::Groups
    mount ::API::GroupMembers
    mount ::API::Users
    mount ::API::Projects
    mount ::API::Repositories
    mount ::API::Issues
    mount ::API::Milestones
    mount ::API::Session
    mount ::API::MergeRequests
    mount ::API::Notes
    mount ::API::Internal
    mount ::API::SystemHooks
    mount ::API::ProjectSnippets
    mount ::API::ProjectMembers
    mount ::API::DeployKeys
    mount ::API::ProjectHooks
    mount ::API::ProjectGitHook
    mount ::API::Ldap
    mount ::API::LdapGroupLinks
    mount ::API::Services
    mount ::API::Files
    mount ::API::Commits
    mount ::API::CommitStatuses
    mount ::API::Namespaces
    mount ::API::Branches
    mount ::API::Labels
    mount ::API::Settings
    mount ::API::Keys
    mount ::API::Tags
    mount ::API::License
    mount ::API::Triggers
    mount ::API::Builds
    mount ::API::Variables
    mount ::API::Runners
    mount ::API::LicenseTemplates
    mount ::API::Subscriptions
    mount ::API::Gitignores
  end
end
