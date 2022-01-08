# frozen_string_literal: true

module Groups
  module CrmSettingsHelper
    def crm_feature_flag_enabled?(group)
      Feature.enabled?(:customer_relations, group)
    end
  end
end
