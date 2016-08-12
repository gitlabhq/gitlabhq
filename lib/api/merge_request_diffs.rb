module API
  # MergeRequestDiff API
  class MergeRequestDiffs < Grape::API
    before { authenticate! }

    resource :projects do
      desc 'Get a list of merge request diff versions' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::MergeRequestDiff
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
        requires :merge_request_id, type: Integer, desc: 'The ID of a merge request'
      end

      get ":id/merge_requests/:merge_request_id/versions" do
        merge_request = user_project.merge_requests.
          find(params[:merge_request_id])

        authorize! :read_merge_request, merge_request
        present merge_request.merge_request_diffs, with: Entities::MergeRequestDiff
      end

      desc 'Get a single merge request diff version' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::MergeRequestDiffFull
      end

      params do
        requires :id, type: String, desc: 'The ID of a project'
        requires :merge_request_id, type: Integer, desc: 'The ID of a merge request'
        requires :version_id, type: Integer, desc: 'The ID of a merge request diff version'
      end

      get ":id/merge_requests/:merge_request_id/versions/:version_id" do
        merge_request = user_project.merge_requests.
          find(params[:merge_request_id])

        authorize! :read_merge_request, merge_request
        present merge_request.merge_request_diffs.find(params[:version_id]), with: Entities::MergeRequestDiffFull
      end
    end
  end
end
