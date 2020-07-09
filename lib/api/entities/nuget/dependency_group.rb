# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class DependencyGroup < Grape::Entity
        expose :id, as: :@id
        expose :type, as: :@type
        expose :target_framework, as: :targetFramework, expose_nil: false
        expose :dependencies, using: ::API::Entities::Nuget::Dependency
      end
    end
  end
end
