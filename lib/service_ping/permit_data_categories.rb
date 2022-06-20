# frozen_string_literal: true

module ServicePing
  class PermitDataCategories
    STANDARD_CATEGORY = 'standard'
    SUBSCRIPTION_CATEGORY = 'subscription'
    OPERATIONAL_CATEGORY = 'operational'
    OPTIONAL_CATEGORY = 'optional'
    CATEGORIES = [
      STANDARD_CATEGORY,
      SUBSCRIPTION_CATEGORY,
      OPERATIONAL_CATEGORY,
      OPTIONAL_CATEGORY
    ].to_set.freeze

    def execute
      CATEGORIES
    end
  end
end

ServicePing::PermitDataCategories.prepend_mod_with('ServicePing::PermitDataCategories')
