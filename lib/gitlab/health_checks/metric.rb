module Gitlab::HealthChecks
  Metric = Struct.new(:name, :value, :labels)
end
