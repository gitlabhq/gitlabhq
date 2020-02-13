# frozen_string_literal: true

module API
  module Entities
    class Runner < Grape::Entity
      expose :id
      expose :description
      expose :ip_address
      expose :active
      expose :instance_type?, as: :is_shared
      expose :name
      expose :online?, as: :online
      expose :status
    end
  end
end
