# frozen_string_literal: true

module RapidDiffs
  class MergeRequestCreationPresenter < BasePresenter
    extend ::Gitlab::Utils::Override

    presents ::MergeRequest, as: :resource

    def initialize(subject, project, diff_view, diff_options, request_params = nil)
      super(subject, diff_view, diff_options, request_params)
      @project = project
    end

    def diffs_stats_endpoint
      project_new_merge_request_diffs_stats_path(@project, request_params)
    end

    def diff_files_endpoint
      project_new_merge_request_diff_files_metadata_path(@project, request_params)
    end

    def diff_file_endpoint
      project_new_merge_request_diff_file_path(@project, request_params)
    end

    override(:reload_stream_url)
    def reload_stream_url(offset: nil, diff_view: nil)
      project_new_merge_request_diffs_stream_path(
        @project,
        **request_params,
        offset: offset,
        view: diff_view
      )
    end

    protected

    override(:offset)
    def offset
      nil
    end
  end
end
