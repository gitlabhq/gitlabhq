# frozen_string_literal: true

module Gitlab::HealthChecks
  Result = Struct.new(:success, :message, :labels)
end
