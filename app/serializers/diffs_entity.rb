# frozen_string_literal: true

class DiffsEntity < Grape::Entity
  include DiffHelper
  include RequestAwareEntity

  expose :real_size
  expose :size

  expose :branch_name do |diffs|
    merge_request&.source_branch
  end

  expose :target_branch_name do |diffs|
    merge_request&.target_branch
  end

  expose :commit do |diffs|
    options[:commit]
  end

  expose :merge_request_diff, using: MergeRequestDiffEntity do |diffs|
    options[:merge_request_diff]
  end

  expose :start_version, using: MergeRequestDiffEntity do |diffs|
    options[:start_version]
  end

  expose :latest_diff do |diffs|
    options[:latest_diff]
  end

  expose :latest_version_path, if: -> (*) { merge_request } do |diffs|
    diffs_project_merge_request_path(merge_request&.project, merge_request)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  expose :added_lines do |diffs|
    diffs.diff_files.sum(&:added_lines)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  # rubocop: disable CodeReuse/ActiveRecord
  expose :removed_lines do |diffs|
    diffs.diff_files.sum(&:removed_lines)
  end
  # rubocop: enable CodeReuse/ActiveRecord

  expose :render_overflow_warning do |diffs|
    render_overflow_warning?(diffs.diff_files)
  end

  expose :email_patch_path, if: -> (*) { merge_request } do |diffs|
    merge_request_path(merge_request, format: :patch)
  end

  expose :plain_diff_path, if: -> (*) { merge_request } do |diffs|
    merge_request_path(merge_request, format: :diff)
  end

  expose :diff_files, using: DiffFileEntity

  expose :merge_request_diffs, using: MergeRequestDiffEntity, if: -> (_, options) { options[:merge_request_diffs]&.any? } do |diffs|
    options[:merge_request_diffs]
  end

  def merge_request
    options[:merge_request]
  end
end
