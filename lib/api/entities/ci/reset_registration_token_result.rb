# frozen_string_literal: true

module API
  module Entities
    module Ci
      class ResetRegistrationTokenResult < Grape::Entity
        expose(:token) {|object| object}
      end
    end
  end
end
