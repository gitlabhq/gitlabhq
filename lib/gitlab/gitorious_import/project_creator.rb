module Gitlab
  module GitoriousImport
    class ProjectCreator
      attr_reader :repo, :namespace, :current_user

      def initialize(repo, namespace, current_user)
        @repo = repo
        @namespace = namespace
        @current_user = current_user
      end

      def execute
        ::Projects::CreateService.new(
          current_user,
          name: repo.name,
          path: repo.path,
          description: repo.description,
          namespace_id: namespace.id,
          visibility_level: Gitlab::VisibilityLevel::PUBLIC,
          import_type: "gitorious",
          import_source: repo.full_name,
          import_url: repo.import_url
        ).execute
      end
    end
  end
end
