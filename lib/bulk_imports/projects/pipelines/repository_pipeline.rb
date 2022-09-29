# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class RepositoryPipeline
        include Pipeline

        abort_on_failure!

        extractor Common::Extractors::GraphqlExtractor, query: Graphql::GetRepositoryQuery

        def transform(_, data)
          data.slice('httpUrlToRepo')
        end

        def load(context, data)
          url = data['httpUrlToRepo']
          return unless url.present?

          url = url.sub("://", "://oauth2:#{context.configuration.access_token}@")
          project = context.portable

          Gitlab::UrlBlocker.validate!(url, schemes: %w[http https], allow_local_network: allow_local_requests?, allow_localhost: allow_local_requests?)

          project.ensure_repository
          project.repository.fetch_as_mirror(url)
        end

        # The initial fetch can bring in lots of loose refs and objects.
        # Running a `git gc` will make importing merge requests faster.
        def after_run(_)
          ::Repositories::HousekeepingService.new(context.portable, :gc).execute
        end

        private

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end
      end
    end
  end
end
