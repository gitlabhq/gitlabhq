class EpicEntity < IssuableEntity
  expose :group_id
  expose :group_name do |epic|
    epic.group.name
  end
  expose :group_full_name do |epic|
    epic.group.full_name
  end
  expose :start_date
  expose :end_date
  expose :web_url do |epic|
    group_epic_path(epic.group, epic)
  end
  expose :labels, using: LabelEntity

  expose :current_user do
    expose :can_create_note do |epic|
      can?(request.current_user, :create_note, epic)
    end
  end

  expose :create_note_path do |epic|
    group_epic_notes_path(epic.group, epic)
  end

  expose :preview_note_path do |epic|
    preview_markdown_path(epic.group, quick_actions_target_type: 'Epic', quick_actions_target_id: epic.id)
  end
end
