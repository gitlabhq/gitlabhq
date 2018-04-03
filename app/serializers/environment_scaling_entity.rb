class EnvironmentScalingEntity < Grape::Entity
  expose :replicas
  expose :available?, as: :available
end
