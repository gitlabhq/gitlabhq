class IssuableEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :iid
  expose :author_id
  expose :description
  expose :lock_version
  expose :milestone_id
  expose :title
  expose :updated_by_id
  expose :created_at
  expose :updated_at
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity
end
