# frozen_string_literal: true

module Groups
  module CrmSettingsHelper
    def crm_feature_available?(group)
      Feature.enabled?(:customer_relations, group)
    end
  end
end
