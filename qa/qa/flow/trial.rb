# frozen_string_literal: true

module QA
  module Flow
    module Trial
      extend self

      CUSTOMER_TRIAL_INFO = {
        company_name: 'QA Test Company',
        number_of_employees: '500 - 1,999',
        telephone_number: '555-555-5555',
        country: 'United States of America',
        state: 'CA'
      }.freeze

      def register_for_trial(group: nil)
        Gitlab::Page::Trials::New.perform do |new|
          new.company_name = CUSTOMER_TRIAL_INFO[:company_name]
          new.number_of_employees = CUSTOMER_TRIAL_INFO[:number_of_employees]
          new.country = CUSTOMER_TRIAL_INFO[:country]
          new.telephone_number = CUSTOMER_TRIAL_INFO[:telephone_number]
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
