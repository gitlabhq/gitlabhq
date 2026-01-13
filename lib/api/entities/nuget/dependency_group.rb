# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class DependencyGroup < Grape::Entity
        expose :id, as: :@id, documentation: { type: 'String', example: 'http://gitlab.com/Sandbox.App/1.0.0.json#dependencygroup' }
        expose :type, as: :@type, documentation: { type: 'String', example: 'PackageDependencyGroup' }
        expose :target_framework, as: :targetFramework, expose_nil: false,
          documentation: { type: 'String', example: 'fwk test' }
        expose :dependencies, using: ::API::Entities::Nuget::Dependency, expose_nil: false,
          documentation: { is_array: true, type: 'API::Entities::Nuget::Dependency' }
      end
    end
  end
end
