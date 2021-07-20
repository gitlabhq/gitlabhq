# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerRegistrationDetails < Grape::Entity
        expose :id, :token
      end
    end
  end
end
