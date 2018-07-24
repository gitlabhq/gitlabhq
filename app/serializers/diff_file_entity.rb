# frozen_string_literal: true

class DiffFileEntity < Grape::Entity
  include RequestAwareEntity
  include BlobHelper
  include CommitsHelper
  include DiffHelper
  include SubmoduleHelper
  include BlobHelper
  include IconsHelper
  include TreeHelper
  include ChecksCollaboration
  include Gitlab::Utils::StrongMemoize

  expose :submodule?, as: :submodule

  expose :submodule_link do |diff_file|
    memoized_submodule_links(diff_file).first
  end

  expose :submodule_tree_url do |diff_file|
    memoized_submodule_links(diff_file).last
  end

  expose :blob, using: BlobEntity

  expose :can_modify_blob do |diff_file|
    merge_request = options[:merge_request]

    next unless diff_file.blob

    if merge_request&.source_project && current_user
      can_modify_blob?(diff_file.blob, merge_request.source_project, merge_request.source_branch)
    else
      false
    end
  end

  expose :file_hash do |diff_file|
    Digest::SHA1.hexdigest(diff_file.file_path)
  end

  expose :file_path
  expose :too_large?, as: :too_large
  expose :collapsed?, as: :collapsed
  expose :new_file?, as: :new_file

  expose :deleted_file?, as: :deleted_file
  expose :renamed_file?, as: :renamed_file
  expose :old_path
  expose :new_path
  expose :mode_changed?, as: :mode_changed
  expose :a_mode
  expose :b_mode
  expose :text?, as: :text
  expose :added_lines
  expose :removed_lines
  expose :diff_refs
  expose :content_sha
  expose :stored_externally?, as: :stored_externally
  expose :external_storage

  expose :load_collapsed_diff_url, if: -> (diff_file, options) { diff_file.text? && options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]
    project = merge_request.target_project

    next unless project

    diff_for_path_namespace_project_merge_request_path(
      namespace_id: project.namespace.to_param,
      project_id: project.to_param,
      id: merge_request.iid,
      old_path: diff_file.old_path,
      new_path: diff_file.new_path,
      file_identifier: diff_file.file_identifier
    )
  end

  expose :formatted_external_url, if: -> (_, options) { options[:environment] } do |diff_file|
    options[:environment].formatted_external_url
  end

  expose :external_url, if: -> (_, options) { options[:environment] } do |diff_file|
    options[:environment].external_url_for(diff_file.new_path, diff_file.content_sha)
  end

  expose :old_path_html do |diff_file|
    old_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    old_path
  end

  expose :new_path_html do |diff_file|
    _, new_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    new_path
  end

  expose :edit_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    options = merge_request.persisted? ? { from_merge_request_iid: merge_request.iid } : {}

    next unless merge_request.source_project

    project_edit_blob_path(merge_request.source_project,
      tree_join(merge_request.source_branch, diff_file.new_path),
      options)
  end

  expose :view_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    project = merge_request.target_project

    next unless project
    next unless diff_file.content_sha

    project_blob_path(project, tree_join(diff_file.content_sha, diff_file.new_path))
  end

  expose :replaced_view_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    image_diff = diff_file.rich_viewer && diff_file.rich_viewer.partial_name == 'image'
    image_replaced = diff_file.old_content_sha && diff_file.old_content_sha != diff_file.content_sha

    merge_request = options[:merge_request]
    project = merge_request.target_project

    next unless project

    project_blob_path(project, tree_join(diff_file.old_content_sha, diff_file.old_path)) if image_diff && image_replaced
  end

  expose :context_lines_path, if: -> (diff_file, _) { diff_file.text? } do |diff_file|
    next unless diff_file.content_sha

    project_blob_diff_path(diff_file.repository.project, tree_join(diff_file.content_sha, diff_file.file_path))
  end

  # Used for inline diffs
  expose :highlighted_diff_lines, if: -> (diff_file, _) { diff_file.text? } do |diff_file|
    diff_file.diff_lines_for_serializer
  end

  # Used for parallel diffs
  expose :parallel_diff_lines, if: -> (diff_file, _) { diff_file.text? }

  def current_user
    request.current_user
  end

  def memoized_submodule_links(diff_file)
    strong_memoize(:submodule_links) do
      if diff_file.submodule?
        submodule_links(diff_file.blob, diff_file.content_sha, diff_file.repository)
      else
        []
      end
    end
  end
end
