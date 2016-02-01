# Environment Variables

## Introduction

Commonly people configure GitLab via the `gitlab.rb` configuration file in the Omnibus package.

But if you prefer to use environment variables we allow that too.

## Supported environment variables

Variable | Type | Explanation
-------- | ---- | -----------
`GITLAB_ROOT_PASSWORD` | string | Sets the password for the `root` user on installation
`GITLAB_HOST` | url | Hostname of the GitLab server includes http or https
`RAILS_ENV` | production / development / staging / test | Rails environment
`DATABASE_URL` | url | For example: postgresql://localhost/blog_development
`GITLAB_EMAIL_FROM` | email | Email address used in the "From" field in mails sent by GitLab
`GITLAB_EMAIL_DISPLAY_NAME` | string | Name used in the "From" field in mails sent by GitLab
`GITLAB_EMAIL_REPLY_TO` | email | Email address used in the "Reply-To" field in mails sent by GitLab
`GITLAB_UNICORN_MEMORY_MIN` | integer | The minimum memory threshold (in bytes) for the Unicorn worker killer
`GITLAB_UNICORN_MEMORY_MAX` | integer | The maximum memory threshold (in bytes) for the Unicorn worker killer

## Complete database variables

The recommended way of specifying your database connection information is to set
the `DATABASE_URL` environment variable. This variable only holds connection
information (adapter, database, username, password, host and port), but not
behavior information (encoding, pool). If you don't want to use `DATABASE_URL`
and/or want to set database behavior information, you will have to:

- copy our template `config/database.yml` file: `cp config/database.yml.env config/database.yml`
- set a value for some `GITLAB_DATABASE_XXX` variables

The list of `GITLAB_DATABASE_XXX` variables that you can set is as follow:

Variable | Default value | Overridden by `DATABASE_URL`?
--- | --- | ---
`GITLAB_DATABASE_ADAPTER` | `postgresql` | Yes
`GITLAB_DATABASE_DATABASE` | `gitlab_#{ENV['RAILS_ENV']` | Yes
`GITLAB_DATABASE_USERNAME` | `root` | Yes
`GITLAB_DATABASE_PASSWORD` | None | Yes
`GITLAB_DATABASE_HOST` | `localhost` | Yes
`GITLAB_DATABASE_PORT` | `5432` | Yes
`GITLAB_DATABASE_ENCODING` | `unicode` | No
`GITLAB_DATABASE_POOL` | `10` | No

## Adding more variables

We welcome merge requests to make more settings configurable via variables.
Please make changes in the `config/initializers/1_settings.rb` file.
Please stick to the naming scheme `GITLAB_#{name in 1_settings.rb in upper case}`.

## Omnibus configuration

It's possible to preconfigure the GitLab image by adding the environment variable: `GITLAB_OMNIBUS_CONFIG` to docker run command.
For more information see the ['preconfigure-docker-container' section in the Omnibus documentation](http://doc.gitlab.com/omnibus/docker/#preconfigure-docker-container).
