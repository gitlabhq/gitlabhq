module Gitlab::HealthChecks
  Result = Struct.new(:success, :message, :labels)
end
