# frozen_string_literal: true

class DiffsMetadataEntity < DiffsEntity
  unexpose :diff_files
  expose :raw_diff_files, as: :diff_files, using: DiffFileMetadataEntity

  expose :conflict_resolution_path do |_, options|
    presenter(options[:merge_request]).conflict_resolution_path
  end

  expose :has_conflicts do |_, options|
    options[:merge_request].cannot_be_merged?
  end

  expose :can_merge do |_, options|
    options[:merge_request].can_be_merged_by?(request.current_user)
  end

  private

  def presenter(merge_request)
    @presenters ||= {}
    @presenters[merge_request] ||= MergeRequestPresenter.new(merge_request, current_user: request.current_user) # rubocop: disable CodeReuse/Presenter
  end
end
