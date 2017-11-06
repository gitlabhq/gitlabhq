module API
  # MergeRequestDiff API
  class MergeRequestDiffs < Grape::API
    include PaginationParams

    before { authenticate! }

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::PROJECT_ENDPOINT_REQUIREMENTS do
      desc 'Get a list of merge request diff versions' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::MergeRequestDiff
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
        use :pagination
      end
      get ":id/merge_requests/:merge_request_iid/versions" do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present paginate(merge_request.merge_request_diffs.order_id_desc), with: Entities::MergeRequestDiff
      end

      desc 'Get a single merge request diff version' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::MergeRequestDiffFull
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
        requires :version_id, type: Integer, desc: 'The ID of a merge request diff version'
      end

      get ":id/merge_requests/:merge_request_iid/versions/:version_id" do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present merge_request.merge_request_diffs.find(params[:version_id]), with: Entities::MergeRequestDiffFull
      end
    end
  end
end
