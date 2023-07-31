# frozen_string_literal: true

# This module is designed for importers that need to create many merge
# requests quickly.  When creating merge requests there are a lot of hooks
# that may run, for many different reasons. Many of these hooks (e.g. the ones
# used for rendering Markdown) are completely unnecessary and may even lead to
# transaction timeouts.
#
# To ensure importing merge requests has a minimal impact and can complete in
# a reasonable time we bypass all the hooks by inserting the row and then
# retrieving it. We then only perform the additional work that is strictly
# necessary.
module Gitlab
  module Import
    class MergeRequestCreator
      include ::Gitlab::Import::DatabaseHelpers
      include ::Gitlab::Import::MergeRequestHelpers

      attr_accessor :project

      def initialize(project)
        @project = project
      end

      def execute(attributes)
        source_branch_sha = attributes.delete(:source_branch_sha)
        target_branch_sha = attributes.delete(:target_branch_sha)
        reviewer_ids = attributes.delete(:reviewer_ids)
        iid = attributes[:iid]

        merge_request, already_exists = create_merge_request_without_hooks(project, attributes, iid)

        if merge_request
          insert_or_replace_git_data(merge_request, source_branch_sha, target_branch_sha, already_exists)
          insert_merge_request_reviewers(merge_request, reviewer_ids)
        end

        merge_request
      end
    end
  end
end
