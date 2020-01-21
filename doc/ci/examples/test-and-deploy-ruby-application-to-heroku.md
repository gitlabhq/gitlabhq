---
type: tutorial
---

# Test and deploy a Ruby application with GitLab CI/CD

This example will guide you through how to run tests in your Ruby on Rails application and deploy it automatically as a Heroku application.

You can also view or fork the complete [example source](https://gitlab.com/ayufan/ruby-getting-started) and view the logs of its past [CI jobs](https://gitlab.com/ayufan/ruby-getting-started/-/jobs?scope=finished).

## Configure the project

This is what the `.gitlab-ci.yml` file looks like for this project:

```yaml
test:
  stage: test
  script:
  - apt-get update -qy
  - apt-get install -y nodejs
  - bundle install --path /cache
  - bundle exec rake db:create RAILS_ENV=test
  - bundle exec rake test

staging:
  stage: deploy
  script:
  - gem install dpl
  - dpl --provider=heroku --app=gitlab-ci-ruby-test-staging --api-key=$HEROKU_STAGING_API_KEY
  only:
  - master

production:
  stage: deploy
  script:
  - gem install dpl
  - dpl --provider=heroku --app=gitlab-ci-ruby-test-prod --api-key=$HEROKU_PRODUCTION_API_KEY
  only:
  - tags
```

This project has three jobs:

- `test` - used to test Rails application.
- `staging` - used to automatically deploy staging environment every push to `master` branch.
- `production` - used to automatically deploy production environment for every created tag.

## Store API keys

You'll need to create two variables in your project's **Settings > CI/CD > Environment variables**:

- `HEROKU_STAGING_API_KEY` - Heroku API key used to deploy staging app.
- `HEROKU_PRODUCTION_API_KEY` - Heroku API key used to deploy production app.

Find your Heroku API key in [Manage Account](https://dashboard.heroku.com/account).

## Create Heroku application

For each of your environments, you'll need to create a new Heroku application.
You can do this through the [Heroku Dashboard](https://dashboard.heroku.com/).

## Create Runner

First install [Docker Engine](https://docs.docker.com/installation/).

To build this project you also need to have [GitLab Runner](https://docs.gitlab.com/runner/).
You can use public runners available on `gitlab.com` or register your own:

```sh
gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "ruby:2.6" \
  --executor "docker" \
  --docker-image ruby:2.6 \
  --docker-postgres latest
```

With the command above, you create a Runner that uses the [ruby:2.6](https://hub.docker.com/_/ruby) image and uses a [postgres](https://hub.docker.com/_/postgres) database.

To access the PostgreSQL database, connect to `host: postgres` as user `postgres` with no password.
