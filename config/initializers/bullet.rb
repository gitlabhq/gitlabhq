# frozen_string_literal: true

if Gitlab::Bullet.configure_bullet?
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true

      if Gitlab::Bullet.extra_logging_enabled?
        Bullet.bullet_logger = true
        Bullet.console = true
      end

      Bullet.raise = Rails.env.test?

      Bullet.stacktrace_excludes = Gitlab::Bullet::Exclusions.new.execute
    end
  end
end
