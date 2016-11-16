class IssuableEntity < Grape::Entity
  expose :id
  expose :iid
  expose :assignee_id
  expose :author_id
  expose :description
  expose :lock_version
  expose :milestone_id
  expose :position
  expose :state
  expose :title
  expose :updated_by_id
  expose :created_at
  expose :updated_at
  expose :deleted_at
  expose :time_estimate
  expose :total_time_spent
  expose :human_time_estimate
  expose :human_total_time_spent
end

