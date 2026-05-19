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

          Gitlab::HTTP_V2::UrlBlocker.validate!(
            url,
            **Import::Framework::UrlBlockerParams.new.to_h
          )

          project.ensure_repository
          project.repository.fetch_as_mirror(url)
        end

        # The initial fetch can bring in lots of loose refs and objects.
        # Running a `git gc` will make importing merge requests faster.
        def after_run(_)
          ::Repositories::HousekeepingService.new(context.portable, :gc).execute
        end
      end
    end
  end
end
