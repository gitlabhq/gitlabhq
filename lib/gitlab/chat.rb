# frozen_string_literal: true

module Gitlab
  module Chat
    # Returns `true` if Chatops is available for the current instance.
    def self.available?
      ::Feature.enabled?(:chatops, default_enabled: true)
    end
  end
end
