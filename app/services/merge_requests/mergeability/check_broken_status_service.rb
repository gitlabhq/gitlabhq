# frozen_string_literal: true
module MergeRequests
  module Mergeability
    class CheckBrokenStatusService < CheckBaseService
      identifier :broken_status
      description 'Checks whether the merge request is broken'

      def execute
        return inactive if Feature.enabled?(:switch_broken_status, merge_request.project, type: :gitlab_com_derisk)

        if merge_request.broken?
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
