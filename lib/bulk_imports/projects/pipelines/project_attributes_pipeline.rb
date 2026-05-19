# frozen_string_literal: true

module BulkImports
  module Projects
    module Pipelines
      class ProjectAttributesPipeline
        include Pipeline

        file_extraction_pipeline!

        relation_name BulkImports::FileTransfer::BaseConfig::SELF_RELATION

        extractor ::BulkImports::Common::Extractors::JsonExtractor, relation: relation

        transformer ::BulkImports::Common::Transformers::ProhibitedAttributesTransformer

        def transform(_context, data)
          subrelations = config.portable_relations_tree.keys.map(&:to_s)

          Gitlab::ImportExport::AttributeCleaner.clean(
            relation_hash: data,
            relation_class: Project,
            excluded_keys: config.relation_excluded_keys(:project)
          ).except(*subrelations)
          .except('name') # name is migrated in the ProjectPipeline
        end

        def load(_context, data)
          # Mark project as importing so default_branch= setter applies
          # the desired branch (it guards on importing? being true).
          portable.importing = true

          portable.assign_attributes(data)
          portable.reconcile_shared_runners_setting!
          portable.drop_visibility_level!
          portable.save!
        end

        def after_run(_context)
          extractor.remove_tmpdir
        end

        private

        def config
          @config ||= BulkImports::FileTransfer.config_for(portable)
        end
      end
    end
  end
end
