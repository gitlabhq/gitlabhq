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
          transformer Import::Offline::Projects::Transformers::ProjectAttributesTransformer

          def load(context, data)
            project = ::Projects::CreateService.new(context.current_user, data).execute

            raise(::BulkImports::Error, project_import_error_message(project)) unless project.persisted?

            context.entity.update!(project: project, organization: nil)

            project.importing = true
            project.default_branch = data['default_branch'] if data['default_branch']
            project.reconcile_shared_runners_setting!

            project.save!

            project
          end

          def after_run(_context)
            extractor.remove_tmpdir
          end

          private

          def project_import_error_message(project)
            "Unable to import project #{project.full_path}. #{project.errors.full_messages}."
          end
        end
      end
    end
  end
end
