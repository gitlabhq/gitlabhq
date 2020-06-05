# frozen_string_literal: true

module SubscribableBannerHelper
  # Overridden in EE
  def display_subscription_banner!
  end
end

SubscribableBannerHelper.prepend_if_ee('EE::SubscribableBannerHelper')
