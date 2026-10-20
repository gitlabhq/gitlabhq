# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # One tier's Explore page, before viewer-specific filtering.
      class ExplorePage < Data.define(:highlights, :credits, :new_items, :enhanced_items); end
    end
  end
end
