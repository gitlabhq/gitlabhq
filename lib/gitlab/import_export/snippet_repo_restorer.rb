# frozen_string_literal: true

module Gitlab
  module ImportExport
    class SnippetRepoRestorer < RepoRestorer
      include ::Import::Framework::ProgressTracking

      attr_reader :snippet, :user

      SnippetRepositoryError = Class.new(StandardError)

      def initialize(snippet:, user:, shared:, path_to_bundle:)
        @snippet = snippet
        @user = user
        @repository = snippet.repository
        @path_to_bundle = path_to_bundle.to_s
        @shared = shared
      end

      def restore
        with_progress_tracking(**progress_tracking_options(snippet)) do
          unless File.exist?(path_to_bundle)
            @shared.logger.info(
              message: '[Snippet Import] Missing repository bundle',
              project_id: snippet.project_id,
              relation_key: 'snippets',
              error_messages: "Repository bundle for snippet #{snippet.id} not found"
            )

            ::ImportFailure.create(
              source: 'SnippetRepoRestorer#restore',
              relation_key: 'snippets',
              exception_class: 'MissingBundleFile',
              exception_message: "Repository bundle for snippet #{snippet.id} not found",
              correlation_id_value: Labkit::Correlation::CorrelationId.current_or_new_id,
              project_id: snippet.project_id
            )

            next true
          end

          create_repository_from_bundle

          true
        end
      rescue StandardError => e
        shared.error(e)
        false
      end

      private

      def create_repository_from_bundle
        repository.create_from_bundle(path_to_bundle)
        snippet.track_snippet_repository(repository.storage)

        response = Snippets::RepositoryValidationService.new(user, snippet).execute

        if response.error?
          repository.remove
          snippet.snippet_repository.delete
          snippet.repository.expire_exists_cache

          raise SnippetRepositoryError, _("Invalid repository bundle for snippet with id %{snippet_id}") % { snippet_id: snippet.id }
        else
          Snippets::UpdateStatisticsService.new(snippet).execute
        end
      end

      def progress_tracking_options(snippet)
        { scope: { project_id: snippet.project_id }, data: snippet.id }
      end
    end
  end
end
