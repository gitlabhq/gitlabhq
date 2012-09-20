rails_root  = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
rails_env   = ENV['RAILS_ENV'] || 'development'
config_file = File.join(rails_root, 'config', 'resque.yml')

if File.exists?(config_file)
  resque_config = YAML.load_file(config_file)
  Resque.redis = resque_config[rails_env]
end
