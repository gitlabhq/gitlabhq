---
type: tutorial
---

# Test and deploy a Python application with GitLab CI/CD

This example will guide you how to run tests in your Python application and deploy it automatically as Heroku application.

You can also view or fork the complete [example source](https://gitlab.com/ayufan/python-getting-started).

## Configure project

This is what the `.gitlab-ci.yml` file looks like for this project:

```yaml
stages:
  - test
  - deploy

test:
  stage: test
  script:
  # this configures Django application to use attached postgres database that is run on `postgres` host
  - export DATABASE_URL=postgres://postgres:@postgres:5432/python-test-app
  - apt-get update -qy
  - apt-get install -y python-dev python-pip
  - pip install -r requirements.txt
  - python manage.py test

staging:
  stage: deploy
  script:
  - apt-get update -qy
  - apt-get install -y ruby-dev
  - gem install dpl
  - dpl --provider=heroku --app=gitlab-ci-python-test-staging --api-key=$HEROKU_STAGING_API_KEY
  only:
  - master

production:
  stage: deploy
  script:
  - apt-get update -qy
  - apt-get install -y ruby-dev
  - gem install dpl
  - dpl --provider=heroku --app=gitlab-ci-python-test-prod --api-key=$HEROKU_PRODUCTION_API_KEY
  only:
  - tags
```

This project has three jobs:

- `test` - used to test Django application.
- `staging` - used to automatically deploy staging environment every push to `master` branch.
- `production` - used to automatically deploy production environment for every created tag.

## Store API keys

You'll need to create two variables in **Settings > CI/CD > Environment variables** in your GitLab project:

- `HEROKU_STAGING_API_KEY` - Heroku API key used to deploy staging app.
- `HEROKU_PRODUCTION_API_KEY` - Heroku API key used to deploy production app.

Find your Heroku API key in [Manage Account](https://dashboard.heroku.com/account).

## Create Heroku application

For each of your environments, you'll need to create a new Heroku application.
You can do this through the [Dashboard](https://dashboard.heroku.com/).

## Create Runner

First install [Docker Engine](https://docs.docker.com/installation/).

To build this project you also need to have [GitLab Runner](https://docs.gitlab.com/runner/index.html).
You can use public runners available on `gitlab.com` or you can register your own:

```sh
gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "PROJECT_REGISTRATION_TOKEN" \
  --description "python-3.5" \
  --executor "docker" \
  --docker-image python:3.5 \
  --docker-services postgres:latest
```

With the command above, you create a runner that uses the [`python:3.5`](https://hub.docker.com/_/python) image and uses a [PostgreSQL](https://hub.docker.com/_/postgres) database.

To access the PostgreSQL database, connect to `host: postgres` as user `postgres` with no password.
