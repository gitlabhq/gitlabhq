# frozen_string_literal: true

module Profiles
  class UsageQuotasController < Profiles::ApplicationController
    include OneTrustCSP

    feature_category :consumables_cost_management
    urgency :low

    def index
      @hide_search_settings = true
      @namespace = current_user.namespace
    end
  end
end

Profiles::UsageQuotasController.prepend_mod
