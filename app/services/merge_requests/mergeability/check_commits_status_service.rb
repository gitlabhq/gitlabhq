# frozen_string_literal: true

module MergeRequests
  module Mergeability
    class CheckCommitsStatusService < CheckBaseService
      identifier :commits_status
      description 'Checks source branch exists and contains commits.'

      def execute
        return inactive unless Feature.enabled?(:switch_broken_status, merge_request.project, type: :gitlab_com_derisk)

        if merge_request.has_no_commits? || merge_request.branch_missing?
          failure
        else
          success
        end
      end

      def skip?
        false
      end

      def cacheable?
        false
      end
    end
  end
end
