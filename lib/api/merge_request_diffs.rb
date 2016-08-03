module API
  # MergeRequestDiff API
  class MergeRequestDiffs < Grape::API
    before { authenticate! }

    resource :projects do
      # List merge requests diff versions
      #
      # Parameters:
      #   id (required)               - The ID of a project
      #   merge_request_id (required) - The ID of MR
      #
      # Example:
      #   GET /projects/:id/merge_requests/:merge_request_id/versions
      #
      get ":id/merge_requests/:merge_request_id/versions" do
        merge_request = user_project.merge_requests.
          find(params[:merge_request_id])

        authorize! :read_merge_request, merge_request
        present merge_request.merge_request_diffs, with: Entities::MergeRequestDiff
      end
    end
  end
end
