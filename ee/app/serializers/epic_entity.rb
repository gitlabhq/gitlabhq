class EpicEntity < IssuableEntity
  expose :group_id
  expose :start_date
  expose :end_date
  expose :web_url do |epic|
    group_epic_path(epic.group, epic)
  end
end
