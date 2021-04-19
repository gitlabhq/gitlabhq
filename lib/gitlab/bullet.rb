# frozen_string_literal: true

module Gitlab
  module Bullet
    extend self

    def enabled?
      Gitlab::Utils.to_boolean(ENV['ENABLE_BULLET'], default: false)
    end
    alias_method :extra_logging_enabled?, :enabled?

    def configure_bullet?
      defined?(::Bullet) && (enabled? || Rails.env.development?)
    end
  end
end
