def bullet_enabled?
  Gitlab::Utils.to_boolean(ENV['ENABLE_BULLET'].to_s)
end

if defined?(Bullet) && (bullet_enabled? || Rails.env.development?)
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true

      Bullet.bullet_logger = bullet_enabled?
      Bullet.console = bullet_enabled?

      Bullet.raise = Rails.env.test?
    end
  end
end
