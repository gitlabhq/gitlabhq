# GitLab CI YMLs

## List GitLab CI YML templates

Get all GitLab CI YML templates.

```
GET /templates/gitlab_ci_ymls
```

```bash
curl https://gitlab.example.com/api/v3/templates/gitlab_ci_ymls
```

Example response:

```json
[
  {
    "name": "C++"
  },
  {
    "name": "Docker"
  },
  {
    "name": "Elixir"
  },
  {
    "name": "LaTeX"
  },
  {
    "name": "Grails"
  },
  {
    "name": "Rust"
  },
  {
    "name": "Nodejs"
  },
  {
    "name": "Ruby"
  },
  {
    "name": "Scala"
  },
  {
    "name": "Maven"
  },
  {
    "name": "Harp"
  },
  {
    "name": "Pelican"
  },
  {
    "name": "Hyde"
  },
  {
    "name": "Nanoc"
  },
  {
    "name": "Octopress"
  },
  {
    "name": "JBake"
  },
  {
    "name": "HTML"
  },
  {
    "name": "Hugo"
  },
  {
    "name": "Metalsmith"
  },
  {
    "name": "Hexo"
  },
  {
    "name": "Lektor"
  },
  {
    "name": "Doxygen"
  },
  {
    "name": "Brunch"
  },
  {
    "name": "Jekyll"
  },
  {
    "name": "Middleman"
  }
]
```

## Single GitLab CI YML template

Get a single GitLab CI YML template.

```
GET /templates/gitlab_ci_ymls/:key
```

| Attribute  | Type   | Required | Description |
| ---------- | ------ | -------- | ----------- |
| `key`      | string | yes      | The key of the GitLab CI YML template |

```bash
curl https://gitlab.example.com/api/v3/templates/gitlab_ci_ymls/Ruby
```

Example response:

```json
{
  "name": "Ruby",
  "content": "# This file is a template, and might need editing before it works on your project.\n# Official language image. Look for the different tagged releases at:\n# https://hub.docker.com/r/library/ruby/tags/\nimage: \"ruby:2.3\"\n\n# Pick zero or more services to be used on all builds.\n# Only needed when using a docker container to run your tests in.\n# Check out: http://docs.gitlab.com/ce/ci/docker/using_docker_images.html#what-is-service\nservices:\n  - mysql:latest\n  - redis:latest\n  - postgres:latest\n\nvariables:\n  POSTGRES_DB: database_name\n\n# Cache gems in between builds\ncache:\n  paths:\n    - vendor/ruby\n\n# This is a basic example for a gem or script which doesn't use\n# services such as redis or postgres\nbefore_script:\n  - ruby -v                                   # Print out ruby version for debugging\n  # Uncomment next line if your rails app needs a JS runtime:\n  # - apt-get update -q && apt-get install nodejs -yqq\n  - gem install bundler  --no-ri --no-rdoc    # Bundler is not installed with the image\n  - bundle install -j $(nproc) --path vendor  # Install dependencies into ./vendor/ruby\n\n# Optional - Delete if not using `rubocop`\nrubocop:\n  script:\n  - rubocop\n\nrspec:\n  script:\n  - rspec spec\n\nrails:\n  variables:\n    DATABASE_URL: \"postgresql://postgres:postgres@postgres:5432/$POSTGRES_DB\"\n  script:\n  - bundle exec rake db:migrate\n  - bundle exec rake db:seed\n  - bundle exec rake test\n"
}
```
