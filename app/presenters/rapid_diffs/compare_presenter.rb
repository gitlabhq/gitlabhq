# frozen_string_literal: true

module RapidDiffs
  class ComparePresenter < BasePresenter
    extend ::Gitlab::Utils::Override

    presents ::Compare, as: :resource

    def diffs_stats_endpoint
      diffs_stats_project_compare_index_path(resource.project, request_params)
    end

    def diff_files_endpoint
      diff_files_metadata_project_compare_index_path(resource.project, request_params)
    end

    def diff_file_endpoint
      diff_file_project_compare_index_path(resource.project, request_params)
    end

    override(:reload_stream_url)
    def reload_stream_url(offset: nil, diff_view: nil)
      diffs_stream_project_compare_index_path(
        resource.project,
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
