# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class DependencyGroup < Grape::Entity
        expose :id, as: :@id, documentation: { type: 'string', example: 'http://gitlab.com/Sandbox.App/1.0.0.json#dependencygroup' }
        expose :type, as: :@type, documentation: { type: 'string', example: 'PackageDependencyGroup' }
        expose :target_framework, as: :targetFramework, expose_nil: false,
          documentation: { type: 'string', example: 'fwk test' }
        expose :dependencies, using: ::API::Entities::Nuget::Dependency,
          documentation: { is_array: true, type: 'API::Entities::Nuget::Dependency' }
      end
    end
  end
end
