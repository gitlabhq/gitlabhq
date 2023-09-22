# frozen_string_literal: true

module API
  # MergeRequestDiff API
  class MergeRequestDiffs < ::API::Base
    include PaginationParams
    include Helpers::Unidiff

    before { authenticate! }

    feature_category :code_review_workflow

    params do
      requires :id, types: [String, Integer], desc: 'The ID or URL-encoded path of the project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      desc 'Get a list of merge request diff versions' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::MergeRequestDiff
        tags %w[merge_requests]
        is_array true
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The internal ID of the merge request'
        use :pagination
      end
      get ":id/merge_requests/:merge_request_iid/versions" do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present paginate(merge_request.merge_request_diffs.order_id_desc), with: Entities::MergeRequestDiff
      end

      desc 'Get a single merge request diff version' do
        detail 'This feature was introduced in GitLab 8.12.'
        success Entities::MergeRequestDiffFull
        tags %w[merge_requests]
      end

      params do
        requires :merge_request_iid, type: Integer, desc: 'The internal ID of the merge request'
        requires :version_id, type: Integer, desc: 'The ID of the merge request diff version'
        use :with_unidiff
      end

      get ":id/merge_requests/:merge_request_iid/versions/:version_id", urgency: :low do
        merge_request = find_merge_request_with_access(params[:merge_request_iid])

        present_cached merge_request.merge_request_diffs.find(params[:version_id]), with: Entities::MergeRequestDiffFull, cache_context: nil, enable_unidiff: declared_params[:unidiff]
      end
    end
  end
end
