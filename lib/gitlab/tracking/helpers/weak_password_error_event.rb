# frozen_string_literal: true

module Gitlab
  module Tracking
    module Helpers
      module WeakPasswordErrorEvent
        # Tracks information if a user record has a weak password.
        # No-op unless the error is present.
        #
        # Captures a minimal set of information, so that GitLab
        # remains unaware of which users / demographics are attempting
        # to choose weak passwords.
        def track_weak_password_error(user, controller, method_name)
          return unless user.errors[:password].grep(/must not contain commonly used combinations.*/).any?

          Gitlab::Tracking.event(
            'Gitlab::Tracking::Helpers::WeakPasswordErrorEvent',
            'track_weak_password_error',
            controller: controller,
            method: method_name
          )
        end
      end
    end
  end
end
