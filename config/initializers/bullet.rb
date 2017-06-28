if defined?(Bullet) && ENV['ENABLE_BULLET']
  Rails.application.configure do
    config.after_initialize do
      Bullet.enable = true

      Bullet.bullet_logger = true
      Bullet.console = true
      Bullet.raise = Rails.env.test?
    end
  end
end
