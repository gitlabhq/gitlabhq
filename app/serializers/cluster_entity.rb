class ClusterEntity < Grape::Entity
  include RequestAwareEntity

  expose :status
  expose :status_reason
end
