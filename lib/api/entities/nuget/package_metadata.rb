# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackageMetadata < Grape::Entity
        expose :json_url, as: :@id
        expose :archive_url, as: :packageContent
        expose :catalog_entry, as: :catalogEntry, using: ::API::Entities::Nuget::PackageMetadataCatalogEntry
      end
    end
  end
end
