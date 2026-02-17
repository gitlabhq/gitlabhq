# frozen_string_literal: true

module RapidDiffs
  class MergeRequestPresenter < BasePresenter
    extend ::Gitlab::Utils::Override

    presents ::MergeRequest, as: :resource

    override(:diffs_resource)
    def diffs_resource(options = {})
      resource.latest_diffs(@diff_options.merge(options))
    end

    def diffs_stats_endpoint
      diffs_stats_project_merge_request_path(resource.project, resource)
    end

    def diff_files_endpoint
      diff_files_metadata_project_merge_request_path(resource.project, resource)
    end

    def diff_file_endpoint
      diff_file_project_merge_request_path(resource.project, resource)
    end

    override(:reload_stream_url)
    def reload_stream_url(offset: nil, diff_view: nil, skip_old_path: nil, skip_new_path: nil)
      diffs_stream_project_merge_request_path(
        resource.project,
        resource,
        offset: offset,
        skip_old_path: skip_old_path,
        skip_new_path: skip_new_path,
        view: diff_view
      )
    end

    def sorted?
      true
    end
  end
end
