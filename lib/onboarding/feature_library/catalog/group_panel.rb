# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # Feature catalog Explore page content for the group sidebar.
      #
      # Adding a paid group nav item? ee/spec/lib/onboarding/feature_library/catalog_drift_spec.rb
      # fails until it has a NavItem here:
      # - item_id, category: the nav item's id and the super sidebar menu it renders under.
      # - title, description, icon: wrap the nav item's own strings in N_(), so no new msgids are needed.
      # - tier, licensed_features: the licensed features that gate the nav item, and their lowest plan.
      # - docs_path: the feature's page under doc/.
      # - shown_on_deployments: only set to limit where the Explore pages show the entry.
      # Growth (@gitlab-org/growth/engineers) reviews catalog changes.
      module GroupPanel
        # Ordered by super sidebar category, as in Catalog::CATEGORIES.
        NAV_ITEMS = [].freeze

        CAPABILITIES = [].freeze
      end
    end
  end
end
