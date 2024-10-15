# frozen_string_literal: true

module API
  module Entities
    module Ci
      module Catalog
        module Resources
          class Version < Grape::Entity
            expose :catalog_url,
              documentation: {
                type: 'string',
                example: 'https://gitlab.example.com/explore/catalog/my-namespace/my-component-project'
              } do |version|
              Gitlab::Routing.url_helpers.explore_catalog_url(version.catalog_resource)
            end
          end
        end
      end
    end
  end
end
