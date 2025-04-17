# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Input < Grape::Entity
        expose :name
        expose :value
      end
    end
  end
end
