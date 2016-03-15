# This is a quick hack to get ExclusiveLease working in GitLab 8.5

module Gitlab
  REDIS_URL = begin
    redis_config_file = Rails.root.join('config/resque.yml')
    if File.exists?(redis_config_file)
      YAML.load_file(redis_config_file)[Rails.env]
    else
      'redis://localhost:6379'
    end
  end
end
