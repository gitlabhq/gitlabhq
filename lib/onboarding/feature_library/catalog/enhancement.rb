# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    module Catalog
      # What a plan adds to a nav item. tier is the plan the text describes: :premium when the
      # Ultimate page inherits Premium text, so viewers who already have Premium can skip it.
      class Enhancement < Data.define(:nav_item, :tier, :text); end
    end
  end
end
