# frozen_string_literal: true

module BulkImports
  module Groups
    class Stage < ::BulkImports::Stage
      private

      # To skip the execution of a pipeline in a specific source instance version, define the attributes
      # `minimum_source_version` and `maximum_source_version`.
      #
      # Use the `minimum_source_version` to inform that the pipeline needs to run when importing from source instances
      # version greater than or equal to the specified minimum source version. For example, if the
      # `minimum_source_version` is equal to 15.1.0, the pipeline will be executed when importing from source instances
      # running versions 15.1.0, 15.1.1, 15.2.0, 16.0.0, etc. And it won't be executed when the source instance version
      # is 15.0.1, 15.0.0, 14.10.0, etc.
      #
      # Use the `maximum_source_version` to inform that the pipeline needs to run when importing from source instance
      # versions less than or equal to the specified maximum source version. For example, if the
      # `maximum_source_version` is equal to 15.1.0, the pipeline will be executed when importing from source instances
      # running versions 15.1.1 (patch), 15.1.0, 15.0.1, 15.0.0, 14.10.0, etc. And it won't be executed when the source
      # instance version is 15.2.0, 15.2.1, 16.0.0, etc.
      #
      # SubGroup Entities must be imported in later stage than Project Entities to avoid `full_path` naming conflicts.

      def config
        base_config = {
          group: {
            pipeline: BulkImports::Groups::Pipelines::GroupPipeline,
            stage: 0
          },
          group_attributes: {
            pipeline: BulkImports::Groups::Pipelines::GroupAttributesPipeline,
            stage: 1
          },
          namespace_settings: {
            pipeline: BulkImports::Groups::Pipelines::NamespaceSettingsPipeline,
            stage: 1,
            minimum_source_version: '15.0.0'
          },
          labels: {
            pipeline: BulkImports::Common::Pipelines::LabelsPipeline,
            stage: 1
          },
          milestones: {
            pipeline: BulkImports::Common::Pipelines::MilestonesPipeline,
            stage: 1
          },
          badges: {
            pipeline: BulkImports::Common::Pipelines::BadgesPipeline,
            stage: 1
          },
          boards: {
            pipeline: BulkImports::Common::Pipelines::BoardsPipeline,
            stage: 2
          },
          uploads: {
            pipeline: BulkImports::Common::Pipelines::UploadsPipeline,
            stage: 2
          },
          subgroups: {
            pipeline: BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline,
            stage: 3 # SubGroup Entities must be imported in later stage
            # to Project Entities to avoid `full_path` naming conflicts.
          },
          finisher: {
            pipeline: BulkImports::Common::Pipelines::EntityFinisher,
            stage: 4
          }
        }

        base_config
          .merge(project_entities_pipeline)
          .merge(members_pipeline)
      end

      def project_entities_pipeline
        if migrate_projects? && project_pipeline_available?
          {
            project_entities: {
              pipeline: BulkImports::Groups::Pipelines::ProjectEntitiesPipeline,
              stage: 2
            }
          }
        else
          {}
        end
      end

      def members_pipeline
        return {} unless migrate_memberships?

        {
          members: {
            pipeline: BulkImports::Common::Pipelines::MembersPipeline,
            stage: 1
          }
        }
      end

      def migrate_projects?
        bulk_import_entity.migrate_projects
      end

      def migrate_memberships?
        bulk_import_entity.migrate_memberships
      end

      def project_pipeline_available?
        @bulk_import.source_version_info >= BulkImport.min_gl_version_for_project_migration
      end
    end
  end
end

::BulkImports::Groups::Stage.prepend_mod_with('BulkImports::Groups::Stage')
