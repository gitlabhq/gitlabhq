# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class ProjectCreator
      attr_reader :repo, :name, :namespace, :current_user, :session_data, :type

      def initialize(repo, name, namespace, current_user, type: :github, **session_data)
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
          description: repo[:description],
          namespace_id: namespace.id,
          organization_id: namespace.organization_id,
          visibility_level: visibility_level,
          import_type: type,
          import_source: repo[:full_name],
          import_url: import_url,
          skip_wiki: skip_wiki,
          import_data: {
            data: {
              user_contribution_mapping_enabled: user_contribution_mapping_enabled
            }
          }
        }.merge!(extra_attrs)

        ::Projects::CreateService.new(current_user, attrs).execute
      end

      private

      def import_url
        repo[:clone_url].sub('://', "://#{session_data[:github_access_token]}@")
      end

      def visibility_level
        visibility_level = repo[:private] ? Gitlab::VisibilityLevel::PRIVATE : @namespace.visibility_level
        visibility_level = Gitlab::CurrentSettings.default_project_visibility if Gitlab::CurrentSettings.restricted_visibility_levels.include?(visibility_level)

        visibility_level
      end

      #
      # If the GitHub project repository has wiki, we should not create the
      # default wiki. Otherwise the GitHub importer will fail because the wiki
      # repository already exist.
      #
      def skip_wiki
        repo[:has_wiki]
      end

      # This checks if user mapping is enabled for Gitea only since GitHub UCM is not yet implemented
      def user_contribution_mapping_enabled
        return false if type != ::Import::SOURCE_GITEA

        Feature.enabled?(:importer_user_mapping, current_user) && Feature.enabled?(:gitea_user_mapping, current_user)
      end
    end
  end
end
