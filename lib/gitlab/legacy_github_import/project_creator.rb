module Gitlab
  module LegacyGithubImport
    class ProjectCreator
      attr_reader :repo, :name, :namespace, :current_user, :session_data, :type

      def initialize(repo, name, namespace, current_user, session_data, type: 'github')
        @repo = repo
        @name = name
        @namespace = namespace
        @current_user = current_user
        @session_data = session_data
        @type = type
      end

      def execute(extra_attrs = {})
        attrs = {
          name: name,
          path: name,
          description: repo.description,
          namespace_id: namespace.id,
          visibility_level: visibility_level,
          import_type: type,
          import_source: repo.full_name,
          import_url: import_url,
          skip_wiki: skip_wiki
        }.merge!(extra_attrs)

        ::Projects::CreateService.new(current_user, attrs).execute
      end

      private

      def import_url
        repo.clone_url.sub('://', "://#{session_data[:github_access_token]}@")
      end

      def visibility_level
        repo.private ? Gitlab::VisibilityLevel::PRIVATE : Gitlab::CurrentSettings.default_project_visibility
      end

      #
      # If the GitHub project repository has wiki, we should not create the
      # default wiki. Otherwise the GitHub importer will fail because the wiki
      # repository already exist.
      #
      def skip_wiki
        repo.has_wiki?
      end
    end
  end
end
