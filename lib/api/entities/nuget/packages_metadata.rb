# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackagesMetadata < Grape::Entity
        expose :count
        expose :items, using: ::API::Entities::Nuget::PackagesMetadataItem
      end
    end
  end
end
