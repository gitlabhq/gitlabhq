GITOSIS = YAML.load_file("#{Rails.root}/config/gitlab.yml")["gitosis"]
EMAIL_OPTS = YAML.load_file("#{Rails.root}/config/gitlab.yml")["email"]
GIT_OPTS = YAML.load_file("#{Rails.root}/config/gitlab.yml")["git"]
