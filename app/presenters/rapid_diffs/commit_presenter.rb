# frozen_string_literal: true

module RapidDiffs
  class CommitPresenter < BasePresenter
    extend ::Gitlab::Utils::Override

    presents ::Commit, as: :resource

    def initialize(subject, diff_view, diff_options, request_params = nil, current_user = nil)
      super(subject, diff_view, diff_options, request_params)
      @current_user = current_user
    end

    def diffs_stats_endpoint
      diffs_stats_project_commit_path(resource.project, resource.id)
    end

    def diff_files_endpoint
      diff_files_metadata_project_commit_path(resource.project, resource.id)
    end

    def diff_file_endpoint
      diff_file_project_commit_path(resource.project, resource.id)
    end

    def discussions_endpoint
      discussions_namespace_project_commit_path(project.namespace, resource.project, resource.id)
    end

    override(:reload_stream_url)
    def reload_stream_url(offset: nil, diff_view: nil)
      diffs_stream_project_commit_path(
        resource.project,
        resource.id,
        offset: offset,
        view: diff_view
      )
    end

    def user_permissions
      {
        can_create_note: can?(@current_user, :create_note, resource.project)
      }
    end
  end
end
