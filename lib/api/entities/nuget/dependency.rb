# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class Dependency < Grape::Entity
        expose :id, as: :@id, documentation: { type: 'string', example: 'http://gitlab.com/Sandbox.App/1.0.0.json#dependency' }
        expose :type, as: :@type, documentation: { type: 'string', example: 'PackageDependency' }
        expose :name, as: :id, documentation: { type: 'string', example: 'Dependency' }
        expose :range, documentation: { type: 'string', example: '2.0.0' }
      end
    end
  end
end
