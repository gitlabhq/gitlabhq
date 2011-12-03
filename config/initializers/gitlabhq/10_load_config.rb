GIT_HOST = YAML.load_file("#{Rails.root}/config/gitlab.yml")["git_host"]
EMAIL_OPTS = YAML.load_file("#{Rails.root}/config/gitlab.yml")["email"]
GIT_OPTS = YAML.load_file("#{Rails.root}/config/gitlab.yml")["git"]
