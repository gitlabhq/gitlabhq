# frozen_string_literal: true

class DiffsEntity < Grape::Entity
  include DiffHelper
  include RequestAwareEntity

  expose :real_size
  expose :size

  expose :branch_name do |diffs|
    merge_request&.source_branch
  end

  expose :source_branch_exists do |diffs|
    merge_request&.source_branch_exists?
  end

  expose :target_branch_name do |diffs|
    merge_request&.target_branch
  end

  expose :commit do |diffs, options|
    CommitEntity.represent(options[:commit], commit_options(options))
  end

  expose :context_commits, using: API::Entities::Commit do |diffs|
    options[:context_commits]
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

  expose :latest_version_path, if: ->(*) { merge_request } do |diffs|
    diffs_project_merge_request_path(merge_request&.project, merge_request)
  end

  expose :added_lines do |diffs|
    diffs.raw_diff_files.sum(&:added_lines)
  end
  expose :removed_lines do |diffs|
    diffs.raw_diff_files.sum(&:removed_lines)
  end
  expose :render_overflow_warning do |diffs|
    render_overflow_warning?(diffs)
  end

  expose :email_patch_path, if: ->(*) { merge_request } do |diffs|
    merge_request_path(merge_request, format: :patch)
  end

  expose :plain_diff_path, if: ->(*) { merge_request } do |diffs|
    merge_request_path(merge_request, format: :diff)
  end

  expose :diff_files do |diffs, options|
    submodule_links = Gitlab::SubmoduleLinks.new(merge_request.project.repository)

    DiffFileEntity.represent(diffs.diff_files,
      options.merge(
        submodule_links: submodule_links,
        code_navigation_path: code_navigation_path(diffs),
        conflicts: conflicts_with_types
      )
    )
  end

  expose :merge_request_diffs, using: MergeRequestDiffEntity, if: ->(_, options) { options[:merge_request_diffs]&.any? } do |diffs|
    options[:merge_request_diffs]
  end

  expose :definition_path_prefix do |diffs|
    next unless merge_request.diff_head_sha

    project_blob_path(merge_request.project, merge_request.diff_head_sha)
  end

  expose :context_commits_diff do |diffs, options|
    next unless merge_request.context_commits_diff.commits_count > 0

    ContextCommitsDiffEntity.represent(
      merge_request.context_commits_diff,
      options
    )
  end

  def merge_request
    options[:merge_request]
  end

  private

  def commit_ids
    @commit_ids ||= merge_request.recent_commits.map(&:id)
  end

  def commit_neighbors(commit_id)
    index = commit_ids.index(commit_id)

    return [] unless index

    [(index > 0 ? commit_ids[index - 1] : nil), commit_ids[index + 1]]
  end

  def commit_options(options)
    next_commit_id, prev_commit_id = *commit_neighbors(options[:commit]&.id)

    options.merge(
      type: :full,
      commit_url_params: { merge_request_iid: merge_request&.iid },
      pipeline_ref: merge_request&.source_branch,
      pipeline_project: merge_request&.source_project,
      prev_commit_id: prev_commit_id,
      next_commit_id: next_commit_id
    )
  end
end
