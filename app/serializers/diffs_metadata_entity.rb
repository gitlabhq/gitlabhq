# frozen_string_literal: true

class DiffsMetadataEntity < DiffsEntity
  unexpose :diff_files
  expose :diff_files do |diffs, options|
    DiffFileMetadataEntity.represent(
      diffs.raw_diff_files(sorted: true),
      options.merge(
        conflicts: conflicts_with_types
      )
    )
  end

  expose :conflict_resolution_path do |_, options|
    presenter(options[:merge_request]).conflict_resolution_path
  end

  # #cannot_be_merged? is generally indicative of conflicts, and is set via
  #   MergeRequests::MergeabilityCheckService. However, it can also indicate
  #   that either #has_no_commits? or #branch_missing? are true.
  #
  expose :has_conflicts do |_, options|
    options[:merge_request].cannot_be_merged?
  end

  expose :can_merge do |_, options|
    options[:merge_request].can_be_merged_by?(request.current_user)
  end

  expose :project_path
  expose :project_name

  expose :username
  expose :user_full_name

  expose :has_encoded_file_paths do |_, options|
    diff =
      if options[:only_context_commits]
        options[:merge_request].context_commits_diff
      else
        options[:merge_request_diff].presence || options[:commit]
      end

    diff&.has_encoded_file_paths?
  end

  private

  def project_path
    request.project&.full_path
  end

  def project_name
    request.project&.name
  end

  def username
    request.current_user&.username
  end

  def user_full_name
    request.current_user&.name
  end

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: request.current_user) # rubocop: disable CodeReuse/Presenter
  end
end
