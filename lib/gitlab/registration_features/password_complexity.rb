# frozen_string_literal: true

module Gitlab
  module RegistrationFeatures
    class PasswordComplexity
      def self.feature_available?
        ::License.feature_available?(:password_complexity) ||
          ::GitlabSubscriptions::Features.usage_ping_feature?(:password_complexity)
      end
    end
  end
end
