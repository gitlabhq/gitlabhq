# frozen_string_literal: true

module Ci
  class StagePolicy < BasePolicy
    delegate :pipeline
  end
end
