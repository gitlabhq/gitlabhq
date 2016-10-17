require 'uri'

module Gitlab
  module GogsImport
    class Importer < Gitlab::GithubImport::Importer
      include Gitlab::ShellAdapter

      attr_reader :client, :errors, :project, :repo, :repo_url

      def initialize(project)
        @project  = project
        @repo     = project.import_source
        @repo_url = project.import_url
        @errors   = []
        @labels   = {}

        if credentials
          uri = URI.parse(project.import_url)
          host = "#{uri.scheme}://#{uri.host}:#{uri.port}#{uri.path}".sub(/[\w-]+\/[\w-]+\.git\z/, '')
          @client = GithubImport::Client.new(credentials[:user], host: host, api_version: 'v1')
        else
          raise Projects::ImportService::Error, "Unable to find project import data credentials for project ID: #{@project.id}"
        end
      end

      def execute
        import_labels
        import_milestones
        import_pull_requests
        import_issues
        import_comments(:issues)
        import_comments(:pull_requests)
        import_wiki
        # NOTE: this is commented out since Gogs doesn't have release-API yet
        # import_releases
        handle_errors

        true
      end

      def import_milestones
        fetch_resources(:milestones, repo, state: :all, per_page: 100) do |milestones|
          milestones.each do |raw|
            begin
              GogsImport::MilestoneFormatter.new(project, raw).create!
            rescue => e
              errors << { type: :milestone, url: Gitlab::UrlSanitizer.sanitize(raw.url), errors: e.message }
            end
          end
        end
      end
    end
  end
end
