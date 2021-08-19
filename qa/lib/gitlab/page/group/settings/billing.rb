# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        class Billing < Chemlab::Page
          # TODO: Supplant with data-qa-selectors
          h4 :billing_plan_header, css: 'div.billing-plan-header h4'

          link :start_your_free_trial

          link :upgrade_to_premium, css: '[data-testid="plan-card-premium"] a.billing-cta-purchase-new'
          link :upgrade_to_ultimate, css: '[data-testid="plan-card-ultimate"] a.billing-cta-purchase-new'
        end
      end
    end
  end
end
