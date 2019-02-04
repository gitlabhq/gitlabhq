# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class ProjectCreator
      attr_reader :repo, :name, :namespace, :current_user, :session_data

      def initialize(repo, name, namespace, current_user, session_data)
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
          import_type: 'bitbucket',
          import_source: repo.full_name,
          import_url: repo.clone_url(session_data[:token]),
          import_data: { credentials: session_data },
          skip_wiki: skip_wiki
        ).execute
      end

      private

      def skip_wiki
        repo.has_wiki?
      end
    end
  end
end
