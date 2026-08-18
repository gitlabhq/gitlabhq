# frozen_string_literal: true

module Import
  module Offline
    module Imports
      module Projects
        class Stage < ::BulkImports::Stage
          private

          def config
            {
              project: {
                pipeline: Import::Offline::Projects::Pipelines::ProjectPipeline,
                stage: 0
              },
              max_iids: {
                pipeline: ::BulkImports::Common::Pipelines::MaxIidsPipeline,
                stage: 1
              },
              repository_bundle: {
                pipeline: ::BulkImports::Projects::Pipelines::RepositoryBundlePipeline,
                stage: 1
              },
              labels: {
                pipeline: ::BulkImports::Common::Pipelines::LabelsPipeline,
                stage: 2
              },
              milestones: {
                pipeline: ::BulkImports::Common::Pipelines::MilestonesPipeline,
                stage: 2
              },
              issues: {
                pipeline: ::BulkImports::Projects::Pipelines::IssuesPipeline,
                stage: 3
              },
              boards: {
                pipeline: ::BulkImports::Common::Pipelines::BoardsPipeline,
                stage: 4
              },
              merge_requests: {
                pipeline: ::BulkImports::Projects::Pipelines::MergeRequestsPipeline,
                stage: 4
              },
              external_pull_requests: {
                pipeline: ::BulkImports::Projects::Pipelines::ExternalPullRequestsPipeline,
                stage: 4
              },
              protected_branches: {
                pipeline: ::BulkImports::Projects::Pipelines::ProtectedBranchesPipeline,
                stage: 4
              },
              project_feature: {
                pipeline: ::BulkImports::Projects::Pipelines::ProjectFeaturePipeline,
                stage: 4
              },
              container_expiration_policy: {
                pipeline: ::BulkImports::Projects::Pipelines::ContainerExpirationPolicyPipeline,
                stage: 4
              },
              service_desk_setting: {
                pipeline: ::BulkImports::Projects::Pipelines::ServiceDeskSettingPipeline,
                stage: 4
              },
              releases: {
                pipeline: ::BulkImports::Projects::Pipelines::ReleasesPipeline,
                stage: 4
              },
              ci_pipelines: {
                pipeline: ::BulkImports::Projects::Pipelines::CiPipelinesPipeline,
                stage: 5
              },
              commit_notes: {
                pipeline: ::BulkImports::Projects::Pipelines::CommitNotesPipeline,
                stage: 5
              },
              uploads: {
                pipeline: ::BulkImports::Common::Pipelines::UploadsPipeline,
                stage: 5
              },
              lfs_objects: {
                pipeline: ::BulkImports::Common::Pipelines::LfsObjectsPipeline,
                stage: 5
              },
              design: {
                pipeline: ::BulkImports::Projects::Pipelines::DesignBundlePipeline,
                stage: 5
              },
              auto_devops: {
                pipeline: ::BulkImports::Projects::Pipelines::AutoDevopsPipeline,
                stage: 5
              },
              pipeline_schedules: {
                pipeline: ::BulkImports::Projects::Pipelines::PipelineSchedulesPipeline,
                stage: 5
              },
              references: {
                pipeline: ::BulkImports::Projects::Pipelines::ReferencesPipeline,
                stage: 5
              },
              # UserContributionsPipeline updates source users created by the
              # preceding relation pipelines. It must run after all relation
              # pipelines.
              user_contributions: {
                pipeline: Import::Offline::Common::Pipelines::UserContributionsPipeline,
                stage: 6
              },
              finisher: {
                pipeline: ::BulkImports::Common::Pipelines::EntityFinisher,
                stage: 7
              }
            }
          end
        end
      end
    end
  end
end

Import::Offline::Imports::Projects::Stage.prepend_mod_with('Import::Offline::Imports::Projects::Stage')
