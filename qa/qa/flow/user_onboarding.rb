# frozen_string_literal: true

module QA
  module Flow
    module UserOnboarding
      extend self

      def onboard_user
        # Implemented in EE only
      end

      def create_initial_project
        # Implemented in EE only
      end
    end
  end
end

QA::Flow::UserOnboarding.prepend_mod_with('Flow::UserOnboarding', namespace: QA)
