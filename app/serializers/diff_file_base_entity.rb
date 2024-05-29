# frozen_string_literal: true

class DiffFileBaseEntity < Grape::Entity
  include RequestAwareEntity
  include BlobHelper
  include DiffHelper
  include TreeHelper
  include ChecksCollaboration
  include Gitlab::Utils::StrongMemoize

  expose :content_sha
  expose :submodule?, as: :submodule

  expose :submodule_link do |diff_file, options|
    memoized_submodule_links(diff_file, options)&.web
  end

  expose :submodule_tree_url do |diff_file|
    memoized_submodule_links(diff_file, options)&.tree
  end

  expose :submodule_compare do |diff_file|
    url = memoized_submodule_links(diff_file, options)&.compare

    next unless url

    {
      url: url,
      old_sha: diff_file.old_blob&.id,
      new_sha: diff_file.blob&.id
    }
  end

  expose :edit_path, if: ->(_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    next unless has_edit_path?(merge_request)

    target_project, target_branch = edit_project_branch_options(merge_request)

    options = merge_request.persisted? && merge_request.source_branch_exists? && !merge_request.merged? ? { from_merge_request_iid: merge_request.iid } : {}

    project_edit_blob_path(target_project, tree_join(target_branch, diff_file.new_path), options)
  end

  expose :ide_edit_path, if: ->(_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    next unless has_edit_path?(merge_request)

    ide_merge_request_path(merge_request, diff_file.new_path)
  end

  expose :old_path_html do |diff_file|
    old_path, _ = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    old_path
  end

  expose :new_path_html do |diff_file|
    _, new_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    new_path
  end

  expose :formatted_external_url, if: ->(_, options) { options[:environment] } do |diff_file|
    options[:environment].formatted_external_url
  end

  expose :external_url, if: ->(_, options) { options[:environment] } do |diff_file|
    options[:environment].external_url_for(diff_file.new_path, diff_file.content_sha)
  end

  expose :blob, using: BlobEntity

  expose :can_modify_blob do |diff_file|
    merge_request = options[:merge_request]

    next unless diff_file.blob

    if merge_request&.source_project && current_user
      can_modify_blob?(diff_file.blob, merge_request.source_project, merge_request.source_branch_exists? ? merge_request.source_branch : merge_request.target_branch)
    else
      false
    end
  end

  expose :file_identifier_hash
  expose :file_hash
  expose :file_path
  expose :old_path
  expose :new_path
  expose :new_file?, as: :new_file
  expose :renamed_file?, as: :renamed_file
  expose :deleted_file?, as: :deleted_file

  expose :diff_refs

  expose :stored_externally?, as: :stored_externally
  expose :external_storage

  expose :mode_changed?, as: :mode_changed
  expose :a_mode
  expose :b_mode

  expose :viewer, using: DiffViewerEntity
  expose :alternate_viewer, using: DiffViewerEntity

  expose :old_size do |diff_file|
    diff_file.old_blob&.raw_size
  end

  expose :new_size do |diff_file|
    diff_file.new_blob&.raw_size
  end

  private

  def memoized_submodule_links(diff_file, options)
    strong_memoize(:submodule_links) do
      next unless diff_file.submodule?

      options[:submodule_links]&.for(diff_file.blob, diff_file.content_sha, diff_file)
    end
  end

  def current_user
    request.current_user
  end

  def edit_project_branch_options(merge_request)
    if merge_request.source_branch_exists? && !merge_request.merged?
      [merge_request.source_project, merge_request.source_branch]
    else
      [merge_request.target_project, merge_request.target_branch]
    end
  end

  def has_edit_path?(merge_request)
    merge_request.merged? || merge_request.source_branch_exists?
  end
end
