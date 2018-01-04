class MergeRequestMetricsEntity < Grape::Entity
  expose :latest_closed_at, as: :closed_at
  expose :merged_at
  expose :latest_closed_by, as: :closed_by, using: UserEntity
  expose :merged_by, using: UserEntity
end
