class DiscussionEntity < Grape::Entity
  include RequestAwareEntity

  expose :id, :reply_id
  expose :position, if: -> (d, _) { defined? d.diff_file }
  expose :line_code, if: -> (d, _) { defined? d.diff_file }
  expose :expanded?, as: :expanded

  expose :notes do |discussion, opts|
    request.note_entity.represent(discussion.notes, opts)
  end

  expose :individual_note?, as: :individual_note
  expose :resolvable?, as: :resolvable
  expose :resolved?, as: :resolved
  expose :resolve_path, if: -> (d, _) { d.resolvable? } do |discussion|
    resolve_project_merge_request_discussion_path(discussion.project, discussion.noteable, discussion.id)
  end
  expose :resolve_with_issue_path, if: -> (d, _) { d.resolvable? } do |discussion|
    new_project_issue_path(discussion.project, merge_request_to_resolve_discussions_of: discussion.noteable.iid, discussion_to_resolve: discussion.id)
  end

  expose :diff_file, using: DiffFileEntity, if: -> (d, _) { defined? d.diff_file }

  expose :diff_discussion?, as: :diff_discussion

  expose :truncated_diff_lines, if: -> (d, _) { (defined? d.diff_file) && d.diff_file.text? } do |discussion|
    options[:context].render_to_string(
      partial: "projects/diffs/line",
      collection: discussion.truncated_diff_lines,
      as: :line,
      locals: { diff_file: discussion.diff_file,
                discussion_expanded: true,
                plain: true },
      layout: false,
      formats: [:html]
    )
  end

  expose :image_diff_html, if: -> (d, _) { defined? d.diff_file } do |discussion|
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
end
