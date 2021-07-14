# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Port < Grape::Entity
          expose :number, :protocol, :name
        end
      end
    end
  end
end
