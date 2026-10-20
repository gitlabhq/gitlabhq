# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # Catalog metadata for a sidebar nav item. Title, description, icon and category copy the
      # nav's own values (checked by ee/spec/lib/onboarding/feature_library/catalog_drift_spec.rb).
      # Strings are stored as msgids (N_) and translated on read with s_, so namespaced nav msgids work.
      # shown_on_deployments limits where Explore pages show the entry: either the nav item only
      # exists there, or product chose not to promote it elsewhere.
      class NavItem < Data.define(
        :item_id, :panel, :category, :tier, :licensed_features,
        :title, :description, :icon, :docs_path, :shown_on_deployments, :enhancements
      )
        def initialize(
          licensed_features: [], shown_on_deployments: Catalog::DEPLOYMENTS, enhancements: {}, **attributes)
          super(
            licensed_features: licensed_features.freeze,
            shown_on_deployments: shown_on_deployments.freeze,
            enhancements: enhancements.freeze,
            **attributes
          )
        end

        def translated_title
          s_(title)
        end

        def translated_description
          s_(description)
        end

        # The page's own plan text, falling back to Premium's on the cumulative Ultimate page.
        def enhancement_for(page)
          tier = page if enhancements.key?(page)
          tier ||= :premium if page == :ultimate && enhancements.key?(:premium)
          return unless tier

          Enhancement.new(nav_item: self, tier: tier, text: s_(enhancements[tier]))
        end
      end
    end
  end
end
