# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Hook < Grape::Entity
          expose :name, :script
        end
      end
    end
  end
end
