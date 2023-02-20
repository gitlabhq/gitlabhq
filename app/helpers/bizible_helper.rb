# frozen_string_literal: true

module BizibleHelper
  def bizible_enabled?(invite_email = nil)
    invite_email.blank? &&
      Feature.enabled?(:ecomm_instrumentation, type: :ops) &&
      Gitlab.config.extra.has_key?('bizible') &&
      Gitlab.config.extra.bizible.present? &&
      Gitlab.config.extra.bizible == true
  end
end
