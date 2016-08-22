module Gitlab
  module BitbucketImport
    class ProjectCreator
      attr_reader :repo, :namespace, :current_user, :session_data

      def initialize(repo, namespace, current_user, session_data)
        @repo = repo
        @namespace = namespace
        @current_user = current_user
        @session_data = session_data
      end

      def execute
        ::Projects::CreateService.new(
          current_user,
          name: repo.name,
          path: repo.slug,
          description: repo.description,
          namespace_id: namespace.id,
          visibility_level: repo.visibility_level,
          import_type: 'bitbucket',
          import_source: repo.full_name,
          import_url: repo.clone_url(@session_data[:token]),
          import_data: { credentials: session_data }
        ).execute
      end
    end
  end
end
