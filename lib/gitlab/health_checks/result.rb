module Gitlab::HealthChecks # rubocop:disable Naming/FileName
  Result = Struct.new(:success, :message, :labels)
end
