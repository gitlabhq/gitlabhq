# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    # The plan a viewer currently holds and which upgrade pages still apply to them. On CE there is
    # no license, so every viewer is on Free and sees both Explore pages. EE overrides the plan,
    # deployment and trial.
    class CurrentPlanContext
      # Ordered lowest to highest tier: tier_pages returns the plans after the base plan.
      PLANS = %i[free premium ultimate].freeze

      def initialize(resource:)
        @resource = resource
      end

      def edition
        :ce
      end

      def deployment
        :self_managed
      end

      def current_plan
        :free
      end

      def trial?
        false
      end

      # The plan the Explore pages compare against. EE overrides it for trials.
      def base_plan
        current_plan
      end

      # The plans the viewer can still upgrade to. The Ultimate page is cumulative, so Free sees both.
      def tier_pages
        PLANS.drop(PLANS.index(base_plan) + 1)
      end

      def to_h
        {
          edition: edition,
          deployment: deployment,
          current_plan: current_plan,
          base_plan: base_plan,
          trial: trial?
        }
      end

      private

      attr_reader :resource
    end
  end
end

Onboarding::FeatureLibrary::CurrentPlanContext.prepend_mod
