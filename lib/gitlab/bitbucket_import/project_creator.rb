# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    class ProjectCreator
      attr_reader :repo, :name, :namespace, :current_user, :credentials

      def initialize(repo, name, namespace, current_user, credentials)
        @repo = repo
        @name = name
        @namespace = namespace
        @current_user = current_user
        @credentials = credentials
      end

      def execute
        ::Projects::CreateService.new(
          current_user,
          name: name,
          path: name,
          description: repo.description,
          namespace_id: namespace.id,
          organization_id: namespace.organization_id,
          visibility_level: repo.visibility_level,
          import_type: 'bitbucket',
          import_source: repo.full_name,
          import_url: clone_url,
          import_data: { credentials: credentials },
          skip_wiki: skip_wiki
        ).execute
      end

      private

      def skip_wiki
        repo.has_wiki?
      end

      def clone_url
        if credentials[:username].present? && credentials[:app_password].present?
          token = "#{credentials[:username]}:#{credentials[:app_password]}"

          return repo.clone_url(token, auth_type: :basic)
        end

        repo.clone_url(credentials[:token])
      end
    end
  end
end
