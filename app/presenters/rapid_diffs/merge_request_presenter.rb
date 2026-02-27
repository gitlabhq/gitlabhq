# frozen_string_literal: true

module RapidDiffs
  class MergeRequestPresenter < BasePresenter
    extend ::Gitlab::Utils::Override

    presents ::MergeRequest, as: :resource

    attr_reader :conflicts

    def initialize(
      subject, diff_view:, diff_options:, current_user: nil, request_params: nil, environment: nil,
      conflicts: nil)
      super(subject, diff_view:, diff_options:, current_user:, request_params:, environment:)
      @conflicts = conflicts
    end

    override(:diffs_resource)
    def diffs_resource(options = {})
      resource.latest_diffs(@diff_options.merge(options))
    end

    def diffs_stats_endpoint
      diffs_stats_project_merge_request_path(resource.project, resource, diff_options_from_params)
    end

    def diff_files_endpoint
      diff_files_metadata_project_merge_request_path(resource.project, resource, diff_options_from_params)
    end

    def diff_file_endpoint
      diff_file_project_merge_request_path(resource.project, resource, diff_options_from_params)
    end

    override(:reload_stream_url)
    def reload_stream_url(offset: nil, diff_view: nil, skip_old_path: nil, skip_new_path: nil)
      diffs_stream_project_merge_request_path(
        resource.project,
        resource,
        diff_options_from_params.merge(
          offset: offset,
          skip_old_path: skip_old_path,
          skip_new_path: skip_new_path,
          view: diff_view
        )
      )
    end

    def sorted?
      true
    end

    protected

    override(:transform_file)
    def transform_file(diff_file)
      file = super
      return file if file.is_a?(MergeRequest::DiffFilePresenter)

      # rubocop: disable CodeReuse/Presenter -- DiffFile is a separate domain from the merge request, we need to represent it differently
      MergeRequest::DiffFilePresenter.new(file, conflicts: @conflicts)
      # rubocop: enable CodeReuse/Presenter
    end

    def diff_options_from_params
      {
        diff_id: request_params[:diff_id],
        start_sha: request_params[:start_sha],
        commit_id: request_params[:commit_id]
      }
    end
  end
end
