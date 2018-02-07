class DiffFileEntity < Grape::Entity
  include DiffHelper
  include SubmoduleHelper
  include BlobHelper
  include IconsHelper
  include ActionView::Helpers::TagHelper

  expose :submodule?, as: :submodule

  expose :submodule_link do |diff_file|
    submodule_links(diff_file.blob, diff_file.content_sha, diff_file.repository).first
  end

  expose :blob_path do |diff_file|
    diff_file.blob.path
  end

  expose :blob_icon do |diff_file|
    blob_icon(diff_file.b_mode, diff_file.file_path)
  end

  expose :file_path
  expose :deleted_file?, as: :deleted_file
  expose :renamed_file?, as: :renamed_file
  expose :old_path
  expose :new_path
  expose :mode_changed?, as: :mode_changed
  expose :a_mode
  expose :b_mode
  expose :text?, as: :text

  expose :old_path_html do |diff_file|
    old_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    old_path
  end

  expose :new_path_html do |diff_file|
    _, new_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    new_path
  end
end
