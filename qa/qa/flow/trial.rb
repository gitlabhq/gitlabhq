# frozen_string_literal: true

module QA
  module Flow
    module Trial
      extend self

      CUSTOMER_TRIAL_INFO = {
        company_name: 'QA Test Company',
        company_size: '500 - 1,999',
        phone_number: '555-555-5555',
        country: 'United States of America',
        state: 'California'
      }.freeze

      def register_for_trial(group: nil)
        Gitlab::Page::Trials::New.perform do |new|
          new.company_name = CUSTOMER_TRIAL_INFO[:company_name]
          new.company_size = CUSTOMER_TRIAL_INFO[:company_size]
          new.country = CUSTOMER_TRIAL_INFO[:country]
          new.phone_number = CUSTOMER_TRIAL_INFO[:phone_number]
          new.state = CUSTOMER_TRIAL_INFO[:state]

          new.continue
        end

        return unless group

        Gitlab::Page::Trials::Select.perform do |select|
          select.subscription_for = group.path
          select.trial_company
          select.start_your_free_trial
        end
      end
    end
  end
end

QA::Flow::Purchase.prepend_mod_with('Flow::Trial', namespace: QA)
