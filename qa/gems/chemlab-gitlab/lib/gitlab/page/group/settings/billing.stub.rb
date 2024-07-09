# frozen_string_literal: true

module Gitlab
  module Page
    module Group
      module Settings
        module Billing
          # @note Defined as +h4 :billing_plan_header+
          # @return [String] The text content or value of +billing_plan_header+
          def billing_plan_header
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::Billing.perform do |billing|
          #     expect(billing.billing_plan_header_element).to exist
          #   end
          # @return [Watir::H4] The raw +H4+ element
          def billing_plan_header_element
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::Billing.perform do |billing|
          #     expect(billing).to be_billing_plan_header
          #   end
          # @return [Boolean] true if the +billing_plan_header+ element is present on the page
          def billing_plan_header?
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @note Defined as +link :start_your_free_trial+
          # Clicks +start_your_free_trial+
          def start_your_free_trial
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::Billing.perform do |billing|
          #     expect(billing.start_your_free_trial_element).to exist
          #   end
          # @return [Watir::Link] The raw +Link+ element
          def start_your_free_trial_element
            # This is a stub, used for indexing. The method is dynamically generated.
          end

          # @example
          #   Gitlab::Page::Group::Settings::Billing.perform do |billing|
          #     expect(billing).to be_start_your_free_trial
          #   end
          # @return [Boolean] true if the +start_your_free_trial+ element is present on the page
          def start_your_free_trial?
            # This is a stub, used for indexing. The method is dynamically generated.
          end
        end
      end
    end
  end
end
