class DiscussionEntity < Grape::Entity
  include RequestAwareEntity
  include NotesHelper

  expose :id, :reply_id
  expose :position, if: -> (d, _) { defined? d.diff_file }
  expose :line_code, if: -> (d, _) { defined? d.diff_file }
  expose :expanded?, as: :expanded
  expose :active?, as: :active, if: -> (d, _) { defined? d.active? }

  expose :notes do |discussion, opts|
    request.note_entity.represent(discussion.notes, opts)
  end

  expose :discussion_path do |discussion|
    discussion_path(discussion)
  end

  expose :individual_note?, as: :individual_note
  expose :resolvable do |discussion|
    discussion.can_resolve?(current_user)
  end

  expose :resolved?, as: :resolved
  expose :resolved_by_push?, as: :resolved_by_push
  expose :resolved_by
  expose :resolved_at
  expose :resolve_path, if: -> (d, _) { d.resolvable? } do |discussion|
    resolve_project_merge_request_discussion_path(discussion.project, discussion.noteable, discussion.id)
  end
  expose :resolve_with_issue_path, if: -> (d, _) { d.resolvable? } do |discussion|
    new_project_issue_path(discussion.project, merge_request_to_resolve_discussions_of: discussion.noteable.iid, discussion_to_resolve: discussion.id)
  end

  expose :diff_file, using: DiffFileEntity, if: -> (discussion, _) { discussion.respond_to?(:diff_file) }

  expose :diff_discussion?, as: :diff_discussion

  expose :truncated_diff_lines_path, if: -> (d, _) { !d.expanded? && !d.resolved_now? } do |discussion|
    project_merge_request_discussion_path(discussion.project, discussion.noteable, discussion)
  end

  expose :truncated_diff_lines, if: -> (d, _) { (defined? d.diff_file) && d.diff_file.text? && (d.expanded? || d.resolved_now?) }

  expose :image_diff_html, if: -> (d, _) { (defined? d.diff_file) && !d.diff_file.text? } do |discussion|
    diff_file = discussion.diff_file
    partial = diff_file.new_file? || diff_file.deleted_file? ? 'single_image_diff' : 'replaced_image_diff'
    options[:context].render_to_string(
      partial: "projects/diffs/#{partial}",
      locals: { diff_file: diff_file,
                position: discussion.position.to_json,
                click_to_comment: false },
      layout: false,
      formats: [:html]
    )
  end

  expose :for_commit?, as: :for_commit
  expose :commit_id

  private

  def current_user
    request.current_user
  end
end
