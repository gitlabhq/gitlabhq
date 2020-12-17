# frozen_string_literal: true

module RolloutStatuses
  class IngressEntity < Grape::Entity
    expose :canary_weight
  end
end
