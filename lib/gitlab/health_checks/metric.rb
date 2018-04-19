module Gitlab::HealthChecks # rubocop:disable Naming/FileName
  Metric = Struct.new(:name, :value, :labels)
end
