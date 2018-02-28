class ClusterEntity < Grape::Entity
  include RequestAwareEntity

  expose :status_name, as: :status
  expose :status_reason
end
