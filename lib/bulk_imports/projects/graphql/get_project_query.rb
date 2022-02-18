# frozen_string_literal: true

module BulkImports
  module Projects
    module Graphql
      class GetProjectQuery
        include Queryable

        def to_s
          <<-'GRAPHQL'
          query($full_path: ID!) {
            project(fullPath: $full_path) {
              description
              visibility
              archived
              created_at: createdAt
              shared_runners_enabled: sharedRunnersEnabled
              container_registry_enabled: containerRegistryEnabled
              only_allow_merge_if_pipeline_succeeds: onlyAllowMergeIfPipelineSucceeds
              only_allow_merge_if_all_discussions_are_resolved: onlyAllowMergeIfAllDiscussionsAreResolved
              request_access_enabled: requestAccessEnabled
              printing_merge_request_link_enabled: printingMergeRequestLinkEnabled
              remove_source_branch_after_merge: removeSourceBranchAfterMerge
              autoclose_referenced_issues: autocloseReferencedIssues
              suggestion_commit_message: suggestionCommitMessage
              wiki_enabled: wikiEnabled
            }
          }
          GRAPHQL
        end
      end
    end
  end
end
