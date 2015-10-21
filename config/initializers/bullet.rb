if ENV['ENABLE_BULLET']
  require 'bullet'

  Bullet.enable  = true
  Bullet.console = true
end
