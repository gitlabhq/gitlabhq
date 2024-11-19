# frozen_string_literal: true

module Gitlab
  module HealthChecks
    Metric = Struct.new(:name, :value, :labels)
  end
end
