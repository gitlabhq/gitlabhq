# Environment Variables

## Introduction

Commonly people configure GitLab via the gitlab.rb configuration file in the Omnibus package.

But if you prefer to use environment variables we allow that too.

## Supported environment variables

Variable | Type | Explanation
--- | --- | ---
GITLAB_ROOT_PASSWORD | string | sets the password for the `root` user on installation
GITLAB_HOST | url | hostname of the GitLab server includes http or https
RAILS_ENV | production/development/staging/test | Rails environment
DATABASE_URL | url | For example: postgresql://localhost/blog_development?pool=5

## Complete database variables

As explained in the [Heroku documentation](https://devcenter.heroku.com/articles/rails-database-connection-behavior) the DATABASE_URL doesn't let you set:

- adapter
- database
- username
- password
- host
- port

To do so please `cp config/database.yml.env config/database.yml` and use the following variables:

Variable | Default
--- | ---
GITLAB_DATABASE_ADAPTER | postgresql
GITLAB_DATABASE_ENCODING | unicode
GITLAB_DATABASE_DATABASE | gitlab_#{ENV['RAILS_ENV']
GITLAB_DATABASE_POOL | 10
GITLAB_DATABASE_USERNAME | root
GITLAB_DATABASE_PASSWORD |
GITLAB_DATABASE_HOST | localhost
GITLAB_DATABASE_PORT | 5432

## Adding more variables

We welcome merge requests to make more settings configurable via variables.
Please stick to the naming scheme "GITLAB_#{name 1_settings.rb in upper case}".

## Omnibus configuration

It's possible to preconfigure the GitLab image by adding the environment variable: `GITLAB_OMNIBUS_CONFIG` to docker run command.
For more information see the ['preconfigure-docker-container' section in the Omnibus documentation](http://doc.gitlab.com/omnibus/docker/#preconfigure-docker-container).
