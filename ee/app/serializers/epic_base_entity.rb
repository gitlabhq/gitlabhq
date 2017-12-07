class EpicBaseEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :title
  expose :url do |epic|
    group_epic_path(epic.group, epic)
  end
end
