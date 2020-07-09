# frozen_string_literal: true

module API
  module Entities
    module Nuget
      class PackageMetadataCatalogEntry < Grape::Entity
        expose :json_url, as: :@id
        expose :authors
        expose :dependency_groups, as: :dependencyGroups, using: ::API::Entities::Nuget::DependencyGroup
        expose :package_name, as: :id
        expose :package_version, as: :version
        expose :tags
        expose :archive_url, as: :packageContent
        expose :summary
        expose :metadatum, using: ::API::Entities::Nuget::Metadatum, merge: true
      end
    end
  end
end
