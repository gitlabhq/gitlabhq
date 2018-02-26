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
end
