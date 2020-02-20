# frozen_string_literal: true

module API
  module Entities
    class CustomAttribute < Grape::Entity
      expose :key
      expose :value
    end
  end
end
