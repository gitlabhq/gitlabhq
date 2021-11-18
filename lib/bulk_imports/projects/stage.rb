# frozen_string_literal: true

module BulkImports
  module Projects
    class Stage < ::BulkImports::Stage
      private

      def config
        @config ||= {
          project: {
            pipeline: BulkImports::Projects::Pipelines::ProjectPipeline,
            stage: 0
          },
          repository: {
            pipeline: BulkImports::Projects::Pipelines::RepositoryPipeline,
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
          issues: {
            pipeline: BulkImports::Projects::Pipelines::IssuesPipeline,
            stage: 3
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
          wiki: {
            pipeline: BulkImports::Common::Pipelines::WikiPipeline,
            stage: 5
          },
          uploads: {
            pipeline: BulkImports::Common::Pipelines::UploadsPipeline,
            stage: 5
          },
          finisher: {
            pipeline: BulkImports::Common::Pipelines::EntityFinisher,
            stage: 6
          }
        }
      end
    end
  end
end

::BulkImports::Projects::Stage.prepend_mod_with('BulkImports::Projects::Stage')
