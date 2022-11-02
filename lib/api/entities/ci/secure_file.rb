# frozen_string_literal: true

module API
  module Entities
    module Ci
      class SecureFile < Grape::Entity
        expose :id
        expose :name
        expose :checksum
        expose :checksum_algorithm
        expose :created_at
        expose :expires_at
        expose :metadata
      end
    end
  end
end
