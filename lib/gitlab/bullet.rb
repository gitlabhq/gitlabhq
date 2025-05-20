# frozen_string_literal: true

module Gitlab
  module Bullet
    extend self

    def enabled?
      Gitlab.config.bullet.enabled
    end

    def extra_logging_enabled?
      Gitlab::Utils.to_boolean(ENV['ENABLE_BULLET'], default: false)
    end

    def configure_bullet?
      Object.const_defined?(:Bullet) && enabled?
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
