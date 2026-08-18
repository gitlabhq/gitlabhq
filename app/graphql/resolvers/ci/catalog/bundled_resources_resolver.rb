# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class BundledResourcesResolver < BaseResolver
        type ::Types::Ci::Catalog::BundledResourceType.connection_type, null: true

        def resolve
          return ::Ci::Catalog::BundledResource.none unless bundled_components_enabled?

          ::Ci::Catalog::BundledResource.ordered_by_id
        end

        private

        def bundled_components_enabled?
          Feature.enabled?(:ci_catalog_bundled_components, current_user)
        end
      end
    end
  end
end
