# frozen_string_literal: true

module Gitlab
  module RenderTimeout
    BACKGROUND = 30.seconds
    FOREGROUND = 1.5.seconds

    def self.timeout(background: BACKGROUND, foreground: FOREGROUND, &block)
      period = Gitlab::Runtime.sidekiq? ? background : foreground

      Timeout.timeout(period, &block)
    end

    def self.banzai_timeout_disabled?
      Gitlab::Utils.to_boolean(ENV['GITLAB_DISABLE_MARKDOWN_TIMEOUT'], default: false)
    end
  end
end
