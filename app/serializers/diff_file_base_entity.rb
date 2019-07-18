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
    memoized_submodule_links(diff_file, options).first
  end

  expose :submodule_tree_url do |diff_file|
    memoized_submodule_links(diff_file, options).last
  end

  expose :edit_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    options = merge_request.persisted? ? { from_merge_request_iid: merge_request.iid } : {}

    next unless merge_request.source_project

    if Feature.enabled?(:web_ide_default)
      ide_edit_path(merge_request.source_project, merge_request.source_branch, diff_file.new_path)
    else
      project_edit_blob_path(merge_request.source_project,
        tree_join(merge_request.source_branch, diff_file.new_path),
        options)
    end
  end

  expose :old_path_html do |diff_file|
    old_path, _ = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    old_path
  end

  expose :new_path_html do |diff_file|
    _, new_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    new_path
  end

  expose :formatted_external_url, if: -> (_, options) { options[:environment] } do |diff_file|
    options[:environment].formatted_external_url
  end

  expose :external_url, if: -> (_, options) { options[:environment] } do |diff_file|
    options[:environment].external_url_for(diff_file.new_path, diff_file.content_sha)
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

  private

  def memoized_submodule_links(diff_file, options)
    strong_memoize(:submodule_links) do
      if diff_file.submodule?
        options[:submodule_links].for(diff_file.blob, diff_file.content_sha)
      else
        []
      end
    end
  end

  def current_user
    request.current_user
  end
end
