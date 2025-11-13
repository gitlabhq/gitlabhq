# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class ProjectCreator
      attr_reader :project_key, :repo_slug, :repo, :name, :namespace, :current_user, :session_data, :timeout_strategy

      def initialize(project_key, repo_slug, repo, name, namespace, current_user, session_data, timeout_strategy)
        @project_key = project_key
        @repo_slug = repo_slug
        @repo = repo
        @name = name
        @namespace = namespace
        @current_user = current_user
        @session_data = session_data
        @timeout_strategy = timeout_strategy
      end

      def execute
        user_contribution_mapping_enabled =
          Feature.enabled?(:bitbucket_server_user_mapping, current_user)

        ::Projects::CreateService.new(
          current_user,
          name: name,
          path: name,
          description: repo.description,
          namespace_id: namespace.id,
          organization_id: namespace.organization_id,
          visibility_level: repo.visibility_level,
          import_type: 'bitbucket_server',
          import_source: repo.browse_url,
          import_url: repo.clone_url,
          import_data: {
            credentials: session_data,
            data: {
              project_key: project_key,
              repo_slug: repo_slug,
              timeout_strategy: timeout_strategy,
              user_contribution_mapping_enabled: user_contribution_mapping_enabled
            }
          },
          skip_wiki: true
        ).execute
      end
    end
  end
end
