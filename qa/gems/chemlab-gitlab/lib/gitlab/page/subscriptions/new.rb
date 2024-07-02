# frozen_string_literal: true

module Gitlab
  module Page
    module Subscriptions
      class New < Chemlab::Page
        path '/subscriptions/new'

        # Purchase Details
        select :plan_name
        select :group_name
        text_field :number_of_users
        text_field :quantity
        button :continue_to_billing, text: /Continue to billing/

        # Billing address
        select :country
        text_field :street_address_1
        text_field :street_address_2
        text_field :city
        select :state
        text_field :zip_code
        button :continue_to_payment, text: /Continue to payment/

        # Payment method
        # TODO: Revisit when https://gitlab.com/gitlab-org/quality/chemlab/-/issues/6 is closed
        iframe :payment_form, id: 'z_hppm_iframe'

        text_field(:name_on_card) { payment_form_element.text_field(id: 'input-creditCardHolderName') }
        text_field(:card_number) { payment_form_element.text_field(id: 'input-creditCardNumber') }
        select(:expiration_month) { payment_form_element.select(id: 'input-creditCardExpirationMonth') }
        select(:expiration_year) { payment_form_element.select(id: 'input-creditCardExpirationYear') }
        text_field(:cvv) { payment_form_element.text_field(id: 'input-cardSecurityCode') }
        link(:review_your_order) { payment_form_element.link(text: /Review your order/) }
        # ENDTODO

        # ToS Acceptance
        div :privacy_and_terms_confirm

        # Confirmation
        button :confirm_purchase, text: /Confirm purchase/

        # Order Summary
        div :selected_plan
        div :total_amount

        # Alerts
        div :lock_competition_error, text: /Operation failed due to a lock competition, please retry later./

        def purchase
          ::QA::Support::Retrier.retry_until(
            max_duration: 80,
            sleep_interval: 10,
            message: 'Expected no Zuora lock competition error'
          ) do
            ::QA::Runtime::Logger.debug('Attempting to purchase subscription')

            privacy_and_terms_confirm_element.click
            confirm_purchase
            ::QA::Support::WaitForRequests.wait_for_requests
            !lock_competition_error?
          end
        end
      end
    end
  end
end
