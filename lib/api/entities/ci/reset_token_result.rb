# frozen_string_literal: true

module API
  module Entities
    module Ci
      class ResetTokenResult < Grape::Entity
        expose(:token)
        expose(:token_expires_at, if: ->(object, options) { object.expirable? })
      end
    end
  end
end
