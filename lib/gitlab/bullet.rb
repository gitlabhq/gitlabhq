# frozen_string_literal: true

module Gitlab
  module Bullet
    extend self

    def enabled?
      Gitlab::Utils.to_boolean(ENV['ENABLE_BULLET'], default: false)
    end
    alias_method :extra_logging_enabled?, :enabled?

    def configure_bullet?
      defined?(::Bullet) && (enabled? || Gitlab.config.bullet.enabled)
    end

    def skip_bullet
      return yield unless configure_bullet?

      ::Bullet.enable = false
      yield
    ensure
      ::Bullet.enable = true if configure_bullet?
    end
  end
end
