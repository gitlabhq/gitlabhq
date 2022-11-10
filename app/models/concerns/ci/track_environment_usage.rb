# frozen_string_literal: true

module Ci
  module TrackEnvironmentUsage
    extend ActiveSupport::Concern

    def track_deployment_usage
      return unless user_id.present? && count_user_deployment?

      Gitlab::Utils::UsageData.track_usage_event('ci_users_executing_deployment_job', user_id)
    end

    def track_verify_environment_usage
      return unless user_id.present? && verifies_environment?

      Gitlab::Utils::UsageData.track_usage_event('ci_users_executing_verify_environment_job', user_id)
    end

    def verifies_environment?
      has_environment_keyword? && environment_action == 'verify'
    end

    def count_user_deployment?
      deployment_name?
    end

    def deployment_name?
      self.class::DEPLOYMENT_NAMES.any? { |n| name.downcase.include?(n) }
    end
  end
end
