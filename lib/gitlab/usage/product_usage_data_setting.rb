# frozen_string_literal: true

module Gitlab
  module Usage
    class ProductUsageDataSetting
      def self.enabled?
        # Environment variable takes highest precedence
        env_enabled = Gitlab::Utils.to_boolean(ENV['GITLAB_PRODUCT_USAGE_DATA_ENABLED'])
        return env_enabled unless env_enabled.nil?

        # Fall back to database setting
        ApplicationSetting.current&.gitlab_product_usage_data_enabled
      end

      def self.source
        Gitlab::Utils.to_boolean(ENV['GITLAB_PRODUCT_USAGE_DATA_ENABLED']).nil? ? :database : :environment
      end
    end
  end
end
