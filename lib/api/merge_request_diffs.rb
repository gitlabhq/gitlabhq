# frozen_string_literal: true

module API
  # MergeRequestDiff API
  class MergeRequestDiffs < ::API::Base
    include PaginationParams

    before { authenticate! }

    feature_category :code_review

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of merge request diff versions' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::MergeRequestDiff
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The IID of a merge request'
        use :pagination
      end
      get ":id/merge_requests/:merge_request_iid/versions" do
        not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

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
        not_found!("Merge Request") unless can?(current_user, :read_merge_request, user_project)

        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present_cached merge_request.merge_request_diffs.find(params[:version_id]), with: Entities::MergeRequestDiffFull, cache_context: nil
      end
    end
  end
end
