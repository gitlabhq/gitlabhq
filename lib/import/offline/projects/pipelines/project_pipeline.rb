# frozen_string_literal: true

module Import
  module Offline
    module Projects
      module Pipelines
        class ProjectPipeline
          include ::BulkImports::Pipeline
          include ::BulkImports::Pipeline::HexdigestCacheStrategy

          file_extraction_pipeline!
          abort_on_failure!

          relation_name ::BulkImports::FileTransfer::BaseConfig::SELF_RELATION

          extractor ::BulkImports::Common::Extractors::JsonExtractor, relation: relation

          transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer
          transformer ::BulkImports::Projects::Transformers::ProjectAttributesTransformer

          def load(context, data)
            project = ::Projects::CreateService.new(context.current_user, data).execute

            if project.persisted?
              context.entity.update!(project: project, organization: nil)

              project
            else
              raise(::BulkImports::Error,
                "Unable to import project #{project.full_path}. #{project.errors.full_messages}.")
            end
          end

          def after_run(_context)
            extractor.remove_tmpdir
          end
        end
      end
    end
  end
end
