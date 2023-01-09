# frozen_string_literal: true
# rubocop:disable Gitlab/NamespacedClass
require 'device_detector'

module Gitlab
  class SafeDeviceDetector < ::DeviceDetector
    USER_AGENT_MAX_SIZE = 1024

    def initialize(user_agent)
      super(user_agent)
      @user_agent = user_agent && user_agent[0..USER_AGENT_MAX_SIZE]
    end
  end
end

# rubocop:enable Gitlab/NamespacedClass
