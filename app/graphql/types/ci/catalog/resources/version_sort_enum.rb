# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        class VersionSortEnum < Types::ReleaseSortEnum
          graphql_name 'CiCatalogResourceVersionSort'
          description 'Values for sorting catalog resource versions'
        end
      end
    end
  end
end
