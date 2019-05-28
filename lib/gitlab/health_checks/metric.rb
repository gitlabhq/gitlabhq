# frozen_string_literal: true

module Gitlab::HealthChecks
  Metric = Struct.new(:name, :value, :labels)
end
