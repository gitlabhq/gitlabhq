# frozen_string_literal: true

module QA
  module Flow
    module MergeRequest
      extend self

      def enable_merge_trains
        Page::Project::Menu.perform(&:go_to_merge_request_settings)
        Page::Project::Settings::MergeRequest.perform(&:enable_merge_trains)
      end

      def enable_merged_results_pipelines
        Page::Project::Menu.perform(&:go_to_merge_request_settings)
        Page::Project::Settings::MergeRequest.perform(&:enable_merged_results)
      end

      # Opens the form to create a new merge request.
      # It tries to use the "Create merge request" button that appears after
      # a commit is pushed, but if that button isn't available, it uses the
      # "New merge request" button on the page that lists merge requests.
      #
      # @param [String] source_branch the branch to be merged
      def create_new(source_branch:)
        if Page::Project::Show.perform(&:has_create_merge_request_button?)
          Page::Project::Show.perform(&:new_merge_request)
          return
        end

        Page::Project::Menu.perform(&:go_to_merge_requests)
        Page::MergeRequest::Index.perform(&:click_new_merge_request)
        Page::MergeRequest::New.perform do |merge_request|
          merge_request.select_source_branch(source_branch)
          merge_request.click_compare_branches_and_continue
        end
      end
    end
  end
end

QA::Flow::MergeRequest.prepend_mod_with('Flow::MergeRequest', namespace: QA)
