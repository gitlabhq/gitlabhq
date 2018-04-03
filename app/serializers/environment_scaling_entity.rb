class EnvironmentScalingEntity < Grape::Entity
  expose :replicas
  expose :available?
end
