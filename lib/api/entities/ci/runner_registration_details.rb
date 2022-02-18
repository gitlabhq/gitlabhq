# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerRegistrationDetails < Grape::Entity
        expose :id, :token, :token_expires_at
      end
    end
  end
end
