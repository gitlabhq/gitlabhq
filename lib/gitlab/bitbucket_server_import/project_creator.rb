module Gitlab
  module BitbucketServerImport
    class ProjectCreator
      attr_reader :project_key, :repo_slug, :repo, :name, :namespace, :current_user, :session_data

      def initialize(project_key, repo_slug, repo, name, namespace, current_user, session_data)
        @project_key = project_key
        @repo_slug = repo_slug
        @repo = repo
        @name = name
        @namespace = namespace
        @current_user = current_user
        @session_data = session_data
      end

      def execute
        ::Projects::CreateService.new(
          current_user,
          name: name,
          path: name,
          description: repo.description,
          namespace_id: namespace.id,
          visibility_level: repo.visibility_level,
          import_type: 'bitbucket_server',
          import_source: repo.browse_url,
          import_url: repo.clone_url,
          import_data: {
            credentials: session_data,
            data: { project_key: project_key, repo_slug: repo_slug }
          },
          skip_wiki: true
        ).execute
      end
    end
  end
end
