## Test and Deploy a ruby application
This example will guide you how to run tests in your Ruby on Rails application and deploy it automatically as Heroku application.

You can checkout the example [source](https://gitlab.com/ayufan/ruby-getting-started) and check [CI status](https://gitlab.com/ayufan/ruby-getting-started/builds?scope=all).

### Configure project
This is what the `.gitlab-ci.yml` file looks like for this project:
```yaml
test:
  script:
  - apt-get update -qy
  - apt-get install -y nodejs
  - bundle install --path /cache
  - bundle exec rake db:create RAILS_ENV=test
  - bundle exec rake test

staging:
  type: deploy
  script:
  - gem install dpl
  - dpl --provider=heroku --app=gitlab-ci-ruby-test-staging --api-key=$HEROKU_STAGING_API_KEY
  only:
  - master

production:
  type: deploy
  script:
  - gem install dpl
  - dpl --provider=heroku --app=gitlab-ci-ruby-test-prod --api-key=$HEROKU_PRODUCTION_API_KEY
  only:
  - tags
```

This project has three jobs:
1. `test` - used to test Rails application,
2. `staging` - used to automatically deploy staging environment every push to `master` branch
3. `production` - used to automatically deploy production environmnet for every created tag

### Store API keys
You'll need to create two variables in `Project > Variables`:
1. `HEROKU_STAGING_API_KEY` - Heroku API key used to deploy staging app,
2. `HEROKU_PRODUCTION_API_KEY` - Heroku API key used to deploy production app.

Find your Heroku API key in [Manage Account](https://dashboard.heroku.com/account).

### Create Heroku application
For each of your environments, you'll need to create a new Heroku application.
You can do this through the [Dashboard](https://dashboard.heroku.com/).

### Create runner
First install [Docker Engine](https://docs.docker.com/installation/).
To build this project you also need to have [GitLab Runner](https://about.gitlab.com/gitlab-ci/#gitlab-runner).
You can use public runners available on `gitlab.com/ci`, but you can register your own:
```
gitlab-ci-multi-runner register \
  --non-interactive \
  --url "https://gitlab.com/ci/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "ruby-2.2" \
  --executor "docker" \
  --docker-image ruby:2.2 \
  --docker-postgres latest
```

With the command above, you create a runner that uses [ruby:2.2](https://hub.docker.com/r/_/ruby/) image and uses [postgres](https://hub.docker.com/r/_/postgres/) database.

To access PostgreSQL database you need to connect to `host: postgres` as user `postgres` without password.
