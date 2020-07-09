# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class Dependency < Grape::Entity
        expose :id, as: :@id
        expose :type, as: :@type
        expose :name, as: :id
        expose :range
      end
    end
  end
end
