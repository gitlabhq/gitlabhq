# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackagesVersions < Grape::Entity
        expose :versions, documentation: { type: 'string', is_array: true, example: '1.3.0.17' }
      end
    end
  end
end
