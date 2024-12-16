# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ProjectPipeline
        include Pipeline
        include HexdigestCacheStrategy

        abort_on_failure!

        extractor ::BulkImports::Common::Extractors::GraphqlExtractor, query: Graphql::GetProjectQuery
        transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer
        transformer ::BulkImports::Projects::Transformers::ProjectAttributesTransformer

        def load(context, data)
          project = ::Projects::CreateService.new(context.current_user, data).execute

          if project.persisted?
            context.entity.update!(project: project, organization: nil)

            project
          else
            raise(::BulkImports::Error, "Unable to import project #{project.full_path}. #{project.errors.full_messages}.")
          end
        end
      end
    end
  end
end
