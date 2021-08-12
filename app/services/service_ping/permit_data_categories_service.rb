# frozen_string_literal: true

module ServicePing
  class PermitDataCategoriesService
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
      return [] unless ServicePingSettings.product_intelligence_enabled?

      CATEGORIES
    end
  end
end

ServicePing::PermitDataCategoriesService.prepend_mod_with('ServicePing::PermitDataCategoriesService')
