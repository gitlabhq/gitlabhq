# frozen_string_literal: true

module QA
  module Flow
    module UserOnboarding
      extend self

      def onboard_user(wait: Capybara.default_max_wait_time)
        # Implemented in EE only
      end
    end
  end
end

QA::Flow::UserOnboarding.prepend_mod_with('Flow::UserOnboarding', namespace: QA)
