# Environment Variables

GitLab exposes certain environment variables which can be used to override
their defaults values.

People usually configure GitLab via `/etc/gitlab/gitlab.rb` for Omnibus
installations, or `gitlab.yml` for installations from source.

Below you will find the supported environment variables which you can use to
override certain values.

## Supported environment variables

Variable | Type | Description
-------- | ---- | -----------
`GITLAB_ROOT_PASSWORD`        | string  | Sets the password for the `root` user on installation
`GITLAB_HOST`                 | string  | The full URL of the GitLab server (including `http://` or `https://`)
`RAILS_ENV`                   | string  | The Rails environment; can be one of `production`, `development`, `staging` or `test`
`DATABASE_URL`                | string  | The database URL; is of the form: `postgresql://localhost/blog_development`
`GITLAB_EMAIL_FROM`           | string  | The e-mail address used in the "From" field in e-mails sent by GitLab
`GITLAB_EMAIL_DISPLAY_NAME`   | string  | The name used in the "From" field in e-mails sent by GitLab
`GITLAB_EMAIL_REPLY_TO`       | string  | The e-mail address used in the "Reply-To" field in e-mails sent by GitLab
`GITLAB_EMAIL_REPLY_TO`       | string  | The e-mail address used in the "Reply-To" field in e-mails sent by GitLab
`GITLAB_EMAIL_SUBJECT_SUFFIX` | string  | The e-mail subject suffix used in e-mails sent by GitLab
`GITLAB_UNICORN_MEMORY_MIN`   | integer | The minimum memory threshold (in bytes) for the Unicorn worker killer
`GITLAB_UNICORN_MEMORY_MAX`   | integer | The maximum memory threshold (in bytes) for the Unicorn worker killer

## Complete database variables

The recommended way of specifying your database connection information is to set
the `DATABASE_URL` environment variable. This variable only holds connection
information (`adapter`, `database`, `username`, `password`, `host` and `port`),
but not behavior information (`encoding`, `pool`). If you don't want to use
`DATABASE_URL` and/or want to set database behavior information, you will have
to either:

- copy our template file: `cp config/database.yml.env config/database.yml`, or
- set a value for some `GITLAB_DATABASE_XXX` variables

The list of `GITLAB_DATABASE_XXX` variables that you can set is:

Variable | Default value | Overridden by `DATABASE_URL`?
-------- | ------------- | -----------------------------
`GITLAB_DATABASE_ADAPTER`   | `postgresql` (for MySQL use `mysql2`) | Yes
`GITLAB_DATABASE_DATABASE`  | `gitlab_#{ENV['RAILS_ENV']`           | Yes
`GITLAB_DATABASE_USERNAME`  | `root`                                | Yes
`GITLAB_DATABASE_PASSWORD`  | None                                  | Yes
`GITLAB_DATABASE_HOST`      | `localhost`                           | Yes
`GITLAB_DATABASE_PORT`      | `5432`                                | Yes
`GITLAB_DATABASE_ENCODING`  | `unicode`                             | No
`GITLAB_DATABASE_POOL`      | `10`                                  | No

## Adding more variables

We welcome merge requests to make more settings configurable via variables.
Please make changes in the `config/initializers/1_settings.rb` file and stick
to the naming scheme `GITLAB_#{name in 1_settings.rb in upper case}`.

## Omnibus configuration

It's possible to preconfigure the GitLab docker image by adding the environment
variable `GITLAB_OMNIBUS_CONFIG` to the `docker run` command.
For more information see the ['preconfigure-docker-container' section in the Omnibus documentation](http://docs.gitlab.com/omnibus/docker/#preconfigure-docker-container).
