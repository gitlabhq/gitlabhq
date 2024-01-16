# frozen_string_literal: true

module QA
  module Flow
    module Purchase
      include Support::Helpers::Plan

      extend self

      def upgrade_subscription(plan: PREMIUM, skip_contact: false)
        Page::Group::Menu.perform(&:go_to_billing)
        Gitlab::Page::Group::Settings::Billing.perform do |billing|
          billing.send("upgrade_to_#{plan[:name].downcase}")
        end

        Gitlab::Page::Subscriptions::New.perform do |new_subscription|
          new_subscription.continue_to_billing
          fill_in_default_info(skip_contact)
          new_subscription.purchase
        end
      end

      def purchase_compute_minutes(quantity: 1, skip_contact: false)
        Page::Group::Menu.perform(&:go_to_usage_quotas)
        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          usage_quota.pipelines_tab
          usage_quota.buy_compute_minutes
        end

        Gitlab::Page::Subscriptions::New.perform do |compute_minutes|
          compute_minutes.quantity = quantity
          compute_minutes.continue_to_billing

          fill_in_default_info(skip_contact)

          compute_minutes.purchase
        end
      end

      def purchase_storage(quantity: 1, skip_contact: false)
        Page::Group::Menu.perform(&:go_to_usage_quotas)
        Gitlab::Page::Group::Settings::UsageQuotas.perform do |usage_quota|
          usage_quota.storage_tab
          usage_quota.purchase_more_storage
        end

        # Purchase checkout opens a new tab but buying additional storage does not
        session = Chemlab.configuration.browser.session.engine
        session.switch_window if session.windows.size == 2

        Gitlab::Page::Subscriptions::New.perform do |storage|
          storage.quantity = quantity
          storage.continue_to_billing

          fill_in_default_info(skip_contact)

          storage.purchase
        end
      end

      def fill_in_customer_info
        Gitlab::Page::Subscriptions::New.perform do |subscription|
          subscription.country = user_billing_info[:country]
          subscription.street_address_1 = user_billing_info[:address_1]
          subscription.street_address_2 = user_billing_info[:address_2]
          subscription.city = user_billing_info[:city]
          subscription.state = user_billing_info[:state]
          subscription.zip_code = user_billing_info[:zip]
        end
      end

      def fill_in_payment_info
        Gitlab::Page::Subscriptions::New.perform do |subscription|
          subscription.name_on_card = credit_card_info[:name]
          subscription.card_number = credit_card_info[:number]
          subscription.expiration_month = credit_card_info[:month]
          subscription.expiration_year = credit_card_info[:year]
          subscription.cvv = credit_card_info[:cvv]
          subscription.review_your_order
        end
      end

      def fill_in_default_info(skip_contact)
        Gitlab::Page::Subscriptions::New.perform do |subscription|
          fill_in_customer_info unless skip_contact
          subscription.continue_to_payment
          fill_in_payment_info
        end
      end

      def credit_card_info
        {
          name: 'QA Test',
          number: '4111111111111111',
          month: '01',
          year: '2025',
          cvv: '232'
        }.freeze
      end

      def user_billing_info
        {
          country: 'United States of America',
          address_1: 'Address 1',
          address_2: 'Address 2',
          city: 'San Francisco',
          state: 'California',
          zip: '94102'
        }.freeze
      end
    end
  end
end

QA::Flow::Purchase.prepend_mod_with('Flow::Purchase', namespace: QA)
