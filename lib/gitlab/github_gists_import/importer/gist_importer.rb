# frozen_string_literal: true

module Gitlab
  module GithubGistsImport
    module Importer
      class GistImporter
        attr_reader :gist, :user

        FileCountLimitError = Class.new(StandardError)
        FILE_COUNT_LIMIT_MESSAGE = 'Snippet maximum file count exceeded'

        # gist - An instance of `Gitlab::GithubGistsImport::Representation::Gist`.
        def initialize(gist, user_id)
          @gist = gist
          @user = User.find(user_id)
        end

        def execute
          snippet = build_snippet
          import_repository(snippet) if snippet.save!

          return ServiceResponse.success unless max_snippet_files_count_exceeded?(snippet)

          fail_and_track(snippet)
        end

        private

        def build_snippet
          attrs = {
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

        def import_repository(snippet)
          resolved_address = get_resolved_address

          snippet.create_repository
          snippet.repository.fetch_as_mirror(gist.git_pull_url, forced: true, resolved_address: resolved_address)
        rescue StandardError
          remove_snippet_and_repository(snippet)

          raise
        end

        def get_resolved_address
          validated_pull_url, host = Gitlab::UrlBlocker.validate!(gist.git_pull_url,
                                      schemes: Project::VALID_IMPORT_PROTOCOLS,
                                      ports: Project::VALID_IMPORT_PORTS,
                                      allow_localhost: allow_local_requests?,
                                      allow_local_network: allow_local_requests?)

          host.present? ? validated_pull_url.host.to_s : ''
        end

        def max_snippet_files_count_exceeded?(snippet)
          snippet.all_files.size > Snippet.max_file_limit
        end

        def remove_snippet_and_repository(snippet)
          snippet.repository.remove if snippet.repository_exists?
          snippet.destroy
        end

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end

        def fail_and_track(snippet)
          remove_snippet_and_repository(snippet)

          ServiceResponse.error(message: FILE_COUNT_LIMIT_MESSAGE).track_exception(as: FileCountLimitError)
        end
      end
    end
  end
end
