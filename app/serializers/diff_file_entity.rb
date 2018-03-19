class DiffFileEntity < Grape::Entity
  include RequestAwareEntity
  include DiffHelper
  include SubmoduleHelper
  include BlobHelper
  include TreeHelper
  include IconsHelper
  include ActionView::Helpers::TagHelper

  expose :submodule?, as: :submodule

  expose :submodule_link do |diff_file|
    submodule_links(diff_file.blob, diff_file.content_sha, diff_file.repository).first
  end

  expose :blob_path do |diff_file|
    diff_file.blob.path
  end

  expose :blob_name do |diff_file|
    diff_file.blob.name
  end

  expose :blob_icon do |diff_file|
    blob_icon(diff_file.b_mode, diff_file.file_path)
  end

  expose :file_hash do |diff_file|
    Digest::SHA1.hexdigest(diff_file.file_path)
  end

  expose :file_path
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

  expose :old_path_html do |diff_file|
    old_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    old_path
  end

  expose :new_path_html do |diff_file|
    _, new_path = mark_inline_diffs(diff_file.old_path, diff_file.new_path)
    new_path
  end

  # TODO check if these are not creating a n+1 call
  # we should probably also pass project as parameter
  expose :edit_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    edit_blob_path(merge_request.source_project, merge_request.source_branch, diff_file.new_path)
  end

  expose :view_path, if: -> (_, options) { options[:merge_request] } do |diff_file|
    merge_request = options[:merge_request]

    project_blob_path(merge_request.source_project, tree_join(merge_request.source_branch, diff_file.new_path))
  end

  expose :context_lines_path, if: -> (diff_file, _) { diff_file.text? } do |diff_file|
    project_blob_diff_path(diff_file.repository.project, tree_join(diff_file.file_path, diff_file.content_sha))
  end

  # Used for inline diffs
  expose :highlighted_diff_lines, if: -> (diff_file, _) { diff_file.text? } do |diff_file|
    lines = diff_file.highlighted_diff_lines

    add_bottom_match_line(lines, diff_file)

    lines
  end

  # Used for parallel diffs
  expose :parallel_diff_lines, if: -> (diff_file, _) { diff_file.text? }

  private

  # This adds the bottom line to the array which contains
  # the data to load more context lines.
  def add_bottom_match_line(lines, diff_file)
    return if lines.empty?

    last_line = lines.last

    return unless last_line.new_pos < total_lines(diff_file.blob)

    match_line = Gitlab::Diff::Line.new("" ,'match', nil, last_line.old_pos, last_line.new_pos)
    lines.push(match_line)
  end

  def total_lines(blob)
    @total_lines ||= begin
      line_count = blob.lines.size
      line_count -= 1 if line_count > 0 && blob.lines.last.blank?
      line_count
    end
  end
end
