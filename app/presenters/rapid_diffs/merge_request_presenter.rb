# frozen_string_literal: true

module RapidDiffs
  class MergeRequestPresenter < BasePresenter
    include ::Gitlab::Utils::StrongMemoize
    delegator_override_with ::Gitlab::Utils::StrongMemoize
    extend ::Gitlab::Utils::Override

    presents ::MergeRequest, as: :resource

    attr_reader :conflicts, :current_user

    def initialize(
      subject, diff_view:, diff_options:,
      current_user: nil, request_params: nil, environment: nil, conflicts: nil
    )
      super(
        ::MergeRequests::VersionedMergeRequest.from_diff_options(subject, diff_options),
        diff_view:, diff_options:, current_user:, request_params:, environment:
      )
      @conflicts = conflicts
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
          view: diff_view,
          only_context_commits: only_context_commits? || nil
        )
      )
    end

    def discussions_endpoint
      discussions_project_merge_request_path(resource.project, resource)
    end

    def only_context_commits?
      request_params&.dig(:only_context_commits) == 'true'
    end

    override(:diffs_slice)
    def diffs_slice
      return if offset.to_i == 0

      @diffs_slice ||= transform_file_collection(resource.first_diffs_slice(offset,
        @diff_options.merge(only_context_commits: only_context_commits?)))
    end

    def sorted?
      true
    end

    def mr_path
      project_merge_request_path(resource.project, resource)
    end

    def project_path
      resource.project.full_path
    end

    def user_permissions
      {
        can_create_note: can?(@current_user, :create_note, resource)
      }
    end

    def noteable_type
      resource.class.name
    end

    def preview_markdown_endpoint
      project_preview_markdown_path(resource.project, target_type: resource.class.name, target_id: resource.iid)
    end

    def markdown_docs_path
      help_page_path('user/markdown.md')
    end

    def suggestions_help_path
      help_page_path('user/project/merge_requests/reviews/suggestions.md')
    end

    def default_suggestion_commit_message
      resource.project.suggestion_commit_message.presence ||
        Gitlab::Suggestions::CommitMessage::DEFAULT_SUGGESTION_COMMIT_MESSAGE
    end

    def register_path
      new_user_registration_path(redirect_to_referer: 'yes')
    end

    def sign_in_path
      new_user_session_path(redirect_to_referer: 'yes')
    end

    def report_abuse_path
      add_category_abuse_reports_path
    end

    def new_comment_template_paths
      [{
        text: _('Your comment templates'),
        href: profile_comment_templates_path
      }]
    end

    def code_review_enabled
      !!@current_user
    end

    def versions
      return unless resource.merge_request_diff&.persisted?

      ::RapidDiffs::DiffCompareVersionsEntity.represent(
        resource,
        diff_id: request_params[:diff_id],
        start_sha: request_params[:start_sha],
        commit_id: request_params[:commit_id]
      ).as_json
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

    override(:transform_file_collection)
    def transform_file_collection(collection)
      collection_unfolder.unfold!(collection)
      collection.write_cache
      super
    end

    private

    def collection_unfolder
      ::Gitlab::Diff::CollectionUnfolder.new(resource, @current_user)
    end
    strong_memoize_attr :collection_unfolder

    def diff_options_from_params
      {
        diff_id: request_params[:diff_id] || resolved_diff_id,
        start_sha: request_params[:start_sha],
        commit_id: request_params[:commit_id],
        only_context_commits: request_params[:only_context_commits]
      }
    end

    def resolved_diff_id
      return if request_params[:commit_id].present?

      version_params = @diff_options.slice(:diff_id, :start_sha)
      resolved_diff = ::Gitlab::MergeRequests::DiffResolver.new(resource, version_params).resolve
      resolved_diff&.id unless resolved_diff.try(:merge_head?)
    end
    strong_memoize_attr :resolved_diff_id
  end
end

RapidDiffs::MergeRequestPresenter.prepend_mod
