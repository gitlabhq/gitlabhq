# frozen_string_literal: true

module API
  module Entities
    class RunnerRegistrationDetails < Grape::Entity
      expose :id, :token
    end
  end
end
