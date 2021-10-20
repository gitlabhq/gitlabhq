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
          url = url.sub("://", "://oauth2:#{context.configuration.access_token}@")

          Gitlab::UrlBlocker.validate!(url, allow_local_network: allow_local_requests?, allow_localhost: allow_local_requests?)

          context.portable.repository.import_repository(url)
        end

        private

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end
      end
    end
  end
end
