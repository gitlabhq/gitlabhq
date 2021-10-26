# rubocop:disable Naming/FileName
# frozen_string_literal: true

module Gitlab
  module HealthChecks
    Metric = Struct.new(:name, :value, :labels)
  end
end

# rubocop:enable Naming/FileName
