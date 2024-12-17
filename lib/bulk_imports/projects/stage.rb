# frozen_string_literal: true

module BulkImports
  module Projects
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

      def config
        base_config = {
          project: {
            pipeline: BulkImports::Projects::Pipelines::ProjectPipeline,
            stage: 0
          },
          repository: {
            pipeline: BulkImports::Projects::Pipelines::RepositoryPipeline,
            maximum_source_version: '15.0.0',
            stage: 1
          },
          repository_bundle: {
            pipeline: BulkImports::Projects::Pipelines::RepositoryBundlePipeline,
            minimum_source_version: '15.1.0',
            stage: 1
          },
          project_attributes: {
            pipeline: BulkImports::Projects::Pipelines::ProjectAttributesPipeline,
            stage: 1
          },
          labels: {
            pipeline: BulkImports::Common::Pipelines::LabelsPipeline,
            stage: 2
          },
          milestones: {
            pipeline: BulkImports::Common::Pipelines::MilestonesPipeline,
            stage: 2
          },
          badges: {
            pipeline: BulkImports::Common::Pipelines::BadgesPipeline,
            stage: 2
          },
          issues: {
            pipeline: BulkImports::Projects::Pipelines::IssuesPipeline,
            stage: 3
          },
          snippets: {
            pipeline: BulkImports::Projects::Pipelines::SnippetsPipeline,
            stage: 3
          },
          snippets_repository: {
            pipeline: BulkImports::Projects::Pipelines::SnippetsRepositoryPipeline,
            stage: 4
          },
          boards: {
            pipeline: BulkImports::Common::Pipelines::BoardsPipeline,
            stage: 4
          },
          merge_requests: {
            pipeline: BulkImports::Projects::Pipelines::MergeRequestsPipeline,
            stage: 4
          },
          external_pull_requests: {
            pipeline: BulkImports::Projects::Pipelines::ExternalPullRequestsPipeline,
            stage: 4
          },
          protected_branches: {
            pipeline: BulkImports::Projects::Pipelines::ProtectedBranchesPipeline,
            stage: 4
          },
          project_feature: {
            pipeline: BulkImports::Projects::Pipelines::ProjectFeaturePipeline,
            stage: 4
          },
          container_expiration_policy: {
            pipeline: BulkImports::Projects::Pipelines::ContainerExpirationPolicyPipeline,
            stage: 4
          },
          service_desk_setting: {
            pipeline: BulkImports::Projects::Pipelines::ServiceDeskSettingPipeline,
            stage: 4
          },
          releases: {
            pipeline: BulkImports::Projects::Pipelines::ReleasesPipeline,
            stage: 4
          },
          ci_pipelines: {
            pipeline: BulkImports::Projects::Pipelines::CiPipelinesPipeline,
            stage: 5
          },
          commit_notes: {
            pipeline: BulkImports::Projects::Pipelines::CommitNotesPipeline,
            minimum_source_version: '15.10.0',
            stage: 5
          },
          wiki: {
            pipeline: BulkImports::Common::Pipelines::WikiPipeline,
            stage: 5
          },
          uploads: {
            pipeline: BulkImports::Common::Pipelines::UploadsPipeline,
            stage: 5
          },
          lfs_objects: {
            pipeline: BulkImports::Common::Pipelines::LfsObjectsPipeline,
            stage: 5
          },
          design: {
            pipeline: BulkImports::Projects::Pipelines::DesignBundlePipeline,
            minimum_source_version: '15.1.0',
            stage: 5
          },
          auto_devops: {
            pipeline: BulkImports::Projects::Pipelines::AutoDevopsPipeline,
            stage: 5
          },
          pipeline_schedules: {
            pipeline: BulkImports::Projects::Pipelines::PipelineSchedulesPipeline,
            stage: 5
          },
          references: {
            pipeline: BulkImports::Projects::Pipelines::ReferencesPipeline,
            stage: 5
          },
          finisher: {
            pipeline: BulkImports::Common::Pipelines::EntityFinisher,
            stage: 7
          }
        }

        base_config.merge(members_pipeline)
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

      def migrate_memberships?
        bulk_import_entity.migrate_memberships
      end
    end
  end
end

::BulkImports::Projects::Stage.prepend_mod_with('BulkImports::Projects::Stage')
