require 'resque/server'
class Authentication
  def initialize(app)
    @app = app
  end

  def call(env)
    account = env['warden'].authenticate!(:database_authenticatable, :rememberable, scope: :user)
    raise "Access denied" if !account.admin?
    @app.call(env)
  end
end

Resque::Server.use Authentication