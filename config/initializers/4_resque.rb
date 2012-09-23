# Custom Redis configuration
rails_root  = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env   = ENV['RAILS_ENV'] || 'development'
config_file = File.join(rails_root, 'config', 'resque.yml')

if File.exists?(config_file)
  resque_config = YAML.load_file(config_file)
  Resque.redis = resque_config[rails_env]
end

# Queues
Resque.watch_queue(PostReceive.instance_variable_get("@queue"))

# Authentication
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

# Mailer
Resque::Mailer.excluded_environments = []
