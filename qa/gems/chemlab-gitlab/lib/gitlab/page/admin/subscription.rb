# frozen_string_literal: true

module Gitlab
  module Page
    module Admin
      class Subscription < Chemlab::Page
        path '/admin/subscription'

        div :subscription_details
        text_field :activation_code
        button :activate
        label :terms_of_services, text: /I agree that/
        button :remove_license
        button :confirm_remove_license
        td :plan
        td :name
        td :company
        td :email
        h2 :users_in_subscription
        table :subscription_history

        div :no_valid_license_alert, text: /no longer has a valid license/
        h3 :no_active_subscription_title, text: /do not have an active subscription/

        def accept_terms
          terms_of_services_element.click # workaround for hidden checkbox
        end

        def remove_license_file
          remove_license
          confirm_remove_license
        end

        # Checks if a subscription record exists in subscription history table
        #
        # @param plan [Hash] Name of the plan
        # @option plan [Hash] Support::Helpers::FREE
        # @option plan [Hash] Support::Helpers::PREMIUM
        # @option plan [Hash] Support::Helpers::PREMIUM_SELF_MANAGED
        # @option plan [Hash] Support::Helpers::ULTIMATE
        # @option plan [Hash] Support::Helpers::ULTIMATE_SELF_MANAGED
        # @option plan [Hash] Support::Helpers::COMPUTE_MINUTES
        # @option plan [Hash] Support::Helpers::STORAGE
        # @param users_in_license [Integer] Number of users in license
        # @param license_type [Hash] Type of the license
        # @option license_type [String] 'license file'
        # @option license_type [String] 'cloud license'
        # @return [Boolean] True if record exists, false if not
        def has_subscription_record?(plan, users_in_license, license_type)
          # find any records that have a matching plan and seats and type
          subscription_history_element.hashes.any? do |record|
            record['Plan'] == plan[:name].capitalize && record['Seats'] == users_in_license.to_s && \
              record['Type'].strip.downcase == license_type
          end
        end
      end
    end
  end
end
