Rails.application.configure do
  config.after_initialize do
    if Rails.env.development? || Rails.env.test? || !!ENV['ENABLE_BULLET']
      require 'bullet'

      Bullet.enable = true

      if Rails.env.development?
        # These settings are only enabled during development so we don't expose
        # unwanted information or log too much to log files.
        Bullet.bullet_logger = true
        Bullet.console = true
      end

      Bullet.unused_eager_loading_enable = false
      Bullet.raise = Rails.env.test?
    end
  end
end
