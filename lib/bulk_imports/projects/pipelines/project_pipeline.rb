# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ProjectPipeline
        include Pipeline
        include HexdigestCacheStrategy
        include Gitlab::InternalEventsTracking

        abort_on_failure!

        extractor ::BulkImports::Common::Extractors::GraphqlExtractor, query: Graphql::GetProjectQuery
        transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer
        transformer ::BulkImports::Projects::Transformers::ProjectAttributesTransformer

        def load(context, data)
          project = ::Projects::CreateService.new(context.current_user, data).execute

          if project.persisted?
            context.entity.update!(project: project, organization: nil)

            track_start_project_import(context.entity)

            project
          else
            raise(::BulkImports::Error, "Unable to import project #{project.full_path}. #{project.errors.full_messages}.")
          end
        end

        private

        def track_start_project_import(entity)
          track_internal_event('start_project_import', entity.project_import_event_attributes)
        end
      end
    end
  end
end
