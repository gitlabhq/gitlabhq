class LabelEntity < Grape::Entity
  expose :id
  expose :title
  expose :color
  expose :description
  expose :group_id
  expose :project_id
  expose :template
  expose :created_at
  expose :updated_at
end
