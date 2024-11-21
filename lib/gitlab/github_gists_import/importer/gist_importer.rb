# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    module Importer
      class GistImporter
        attr_reader :gist, :user, :snippet

        FileCountLimitError = Class.new(StandardError)
        RepoSizeLimitError = Class.new(StandardError)
        SnippetRepositoryError = Class.new(StandardError)
        FILE_COUNT_LIMIT_MESSAGE = 'Snippet maximum file count exceeded'
        REPO_SIZE_LIMIT_MESSAGE = 'Snippet repository size exceeded'

        # gist - An instance of `Gitlab::GithubGistsImport::Representation::Gist`.
        def initialize(gist, user_id)
          @gist = gist
          @user = User.find(user_id)
        end

        # Marking for refactor in:
        # https://gitlab.com/gitlab-org/gitlab/-/issues/469564
        # We'll want to use the Snippets::CreateService here.
        def execute
          validate_gist!

          @snippet = build_snippet
          import_repository if snippet.save!
          validate_repository!

          ServiceResponse.success
        rescue FileCountLimitError, RepoSizeLimitError, SnippetRepositoryError => exception
          fail_and_track(snippet, exception)
        end

        private

        # Duplicate logic in
        # app/services/snippets/create_service.rb
        # Remove as part of refactor in: https://gitlab.com/gitlab-org/gitlab/-/issues/469564
        def organization_id
          user.organizations.first.id
        end

        def build_snippet
          attrs = {
            organization_id: organization_id,
            title: gist.truncated_title,
            visibility_level: gist.visibility_level,
            content: gist.first_file[:file_content],
            file_name: gist.first_file[:file_name],
            author: user,
            created_at: gist.created_at,
            updated_at: gist.updated_at
          }

          PersonalSnippet.new(attrs)
        end

        def import_repository
          resolved_address = get_resolved_address

          snippet.create_repository
          snippet.repository.fetch_as_mirror(gist.git_pull_url, forced: true, resolved_address: resolved_address)
        rescue StandardError
          remove_snippet_and_repository

          raise
        end

        def get_resolved_address
          validated_pull_url, host = Gitlab::HTTP_V2::UrlBlocker.validate!(
            gist.git_pull_url,
            schemes: Project::VALID_IMPORT_PROTOCOLS,
            ports: Project::VALID_IMPORT_PORTS,
            allow_localhost: allow_local_requests?,
            allow_local_network: allow_local_requests?,
            deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
            outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
          )

          host.present? ? validated_pull_url.host.to_s : ''
        end

        def check_gist_files_count!
          return if gist.files.count <= Snippet.max_file_limit

          raise FileCountLimitError, FILE_COUNT_LIMIT_MESSAGE
        end

        def check_gist_repo_size!
          return if gist.total_files_size <= Gitlab::CurrentSettings.snippet_size_limit

          raise RepoSizeLimitError, REPO_SIZE_LIMIT_MESSAGE
        end

        def remove_snippet_and_repository
          snippet.repository.remove if snippet.repository_exists?
          snippet.destroy
        end

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end

        def fail_and_track(snippet, exception)
          remove_snippet_and_repository if snippet

          ServiceResponse.error(message: exception.message).track_exception(as: exception.class)
        end

        def validate_gist!
          check_gist_files_count!
          check_gist_repo_size!
        end

        def validate_repository!
          result = Snippets::RepositoryValidationService.new(user, snippet).execute

          raise SnippetRepositoryError, result.message if result.error?
        end
      end
    end
  end
end
