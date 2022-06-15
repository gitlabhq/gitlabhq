# frozen_string_literal: true

module Gitlab
  module RenderTimeout
    BACKGROUND = 30.seconds
    FOREGROUND = 1.5.seconds

    def self.timeout(background: BACKGROUND, foreground: FOREGROUND, &block)
      period = Gitlab::Runtime.sidekiq? ? background : foreground

      Timeout.timeout(period, &block)
    end
  end
end
