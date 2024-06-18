# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackagesMetadata < Grape::Entity
        expose :count, documentation: { type: 'integer', example: 1 }
        expose :items, using: ::API::Entities::Nuget::PackagesMetadataItem,
          documentation: { is_array: true, type: 'API::Entities::Nuget::PackagesMetadataItem' }
      end
    end
  end
end
