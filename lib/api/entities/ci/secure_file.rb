# frozen_string_literal: true

module API
  module Entities
    module Ci
      class SecureFile < Grape::Entity
        expose :id
        expose :name
        expose :permissions
        expose :checksum
        expose :checksum_algorithm
      end
    end
  end
end
