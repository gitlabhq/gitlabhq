# frozen_string_literal: true

module Onboarding
  module FeatureLibrary
    # The call to action in an Explore page header. CE has no license to upgrade, so it has no CTA.
    # EE overrides #build to route by plan and role.
    class UpgradeCta
      # plan is the page the CTA belongs to (:premium or :ultimate). base_plan is the plan the
      # viewer holds, or returns to when a trial ends.
      def initialize(user:, resource:, plan:, base_plan: :free)
        @user = user
        @resource = resource
        @plan = plan
        @base_plan = base_plan
      end

      def build
        nil
      end

      private

      attr_reader :user, :resource, :plan, :base_plan
    end
  end
end

Onboarding::FeatureLibrary::UpgradeCta.prepend_mod
