## Migrate GitLab CI to GitLab CE or EE

Beginning with version 8.0 of GitLab Community Edition (CE) and Enterprise
Edition (EE), GitLab CI is no longer its own application, but is instead built
into the CE and EE applications.

This guide will detail the process of migrating your CI installation and data
into your GitLab CE or EE installation.

### Before we begin

**You need to have a working installation of GitLab CI version 7.14 to perform
this migration. The older versions are not supported and will most likely break
this migration procedure.**

This migration cannot be performed online and takes a significant amount of
time. Make sure to plan ahead.

If you are running a version of GitLab CI prior to 7.14 please follow the
appropriate [update guide](https://gitlab.com/gitlab-org/gitlab-ci/blob/master/doc/update/).

The migration is divided into three parts:

1. [GitLab CI](#part-i-gitlab-ci)
1. [Gitlab CE (or EE)](#part-ii-gitlab-ce-or-ee)
1. [Finishing Up](#part-iii-finishing-up)

### Part I: GitLab CI

#### 1. Stop GitLab CI

    sudo service gitlab_ci stop

#### 2. Create a backup

The migration procedure modifies the structure of the CI database. If something
goes wrong, you will not be able to revert to a previous version without a
backup:

```bash
cd /home/gitlab_ci/gitlab-ci
sudo -u gitlab_ci -H bundle exec backup:create RAILS_ENV=production
```

#### 3. Rename database tables

To prevent naming conflicts with database tables in GitLab CE or EE, we need to
rename CI's tables to begin with a `ci_` prefix:

```sh
cat <<EOF | bundle exec rails dbconsole production
ALTER TABLE application_settings RENAME TO ci_application_settings;
ALTER TABLE builds RENAME TO ci_builds;
ALTER TABLE commits RENAME TO ci_commits;
ALTER TABLE events RENAME TO ci_events;
ALTER TABLE jobs RENAME TO ci_jobs;
ALTER TABLE projects RENAME TO ci_projects;
ALTER TABLE runner_projects RENAME TO ci_runner_projects;
ALTER TABLE runners RENAME TO ci_runners;
ALTER TABLE services RENAME TO ci_services;
ALTER TABLE tags RENAME TO ci_tags;
ALTER TABLE taggings RENAME TO ci_taggings;
ALTER TABLE trigger_requests RENAME TO ci_trigger_requests;
ALTER TABLE triggers RENAME TO ci_triggers;
ALTER TABLE variables RENAME TO ci_variables;
ALTER TABLE web_hooks RENAME TO ci_web_hooks;
EOF
```

#### 4. Remove cronjob

```
cd /home/gitlab_ci/gitlab-ci
sudo -u gitlab_ci -H bundle exec whenever --clear-crontab
```

#### 5. Create a database dump

In this step, you will need to know information about both your CI and CE (or
EE) databases, such as the server types, hosts, and ports, and the usernames and
passwords.

We can obtain the necessary information from the `config/database.yml` files for
each installation.

1. Get the information for the CI database:

    ```sh
    cat /home/gitlab_ci/gitlab-ci/config/database.yml
    ```

1. Then for the CE (or EE) database:

    ```sh
    cat /home/git/gitlab/config/database.yml
    ```

1. The output of each command should look something like this:

    ```yml
    production:
      adapter: postgresql (or mysql2)
      encoding: utf8
      reconnect: false
      database: GITLAB_CI_DATABASE
      pool: 5
      username: DB_USERNAME
      password: DB_PASSWORD
      host: DB_HOSTNAME
      port: DB_PORT
      # socket: /tmp/mysql.sock
    ```

1. Depending on the values for `adapter`, you will have to use different
   commands to perform the database dump.

    **NOTE:** For any of the commands below, you'll need to substitute the
    values `IN_UPPERCASE` with the corresponding values from your **CI
    installation's** `config/database.yml` files above.

      - If both your CI and CE (or EE) installations use **mysql2** as the `adapter`, use
        `mysqldump`:

          ```sh
          mysqldump --default-character-set=utf8 --complete-insert --no-create-info \
            --host=DB_USERNAME --port=DB_PORT --user=DB_HOSTNAME -p GITLAB_CI_DATABASE \
            ci_application_settings ci_builds ci_commits ci_events ci_jobs ci_projects \
            ci_runner_projects ci_runners ci_services ci_tags ci_taggings ci_trigger_requests \
            ci_triggers ci_variables ci_web_hooks > gitlab_ci.sql
          ```

      - If both your CI and CE (or EE) installations use **postgresql** as the
        `adapter`, use `pg_dump`:

          ```sh
          pg_dump -h DB_HOSTNAME -U DB_USERNAME -p DB_PORT \
            --data-only GITLAB_CI_DATABASE -t "ci_*" > gitlab_ci.sql
          ```

      - If your CI installation uses **mysql2** as the `adapter` and your CE (or
        EE) installation uses **postgresql**, use `mysqldump` to dump the database
        and then convert it to PostgreSQL using [mysql-postgresql-converter]:

          ```sh
          # Dump existing MySQL database first
          mysqldump --default-character-set=utf8 --compatible=postgresql --complete-insert \
            --host=DB_USERNAME --port=DB_PORT --user=DB_HOSTNAME -p GITLAB_CI_DATABASE \
            ci_application_settings ci_builds ci_commits ci_events ci_jobs ci_projects \
            ci_runner_projects ci_runners ci_services ci_tags ci_taggings ci_trigger_requests \
            ci_triggers ci_variables ci_web_hooks > gitlab_ci.sql.tmp

          # Convert database to be compatible with PostgreSQL
          git clone https://github.com/gitlabhq/mysql-postgresql-converter.git -b gitlab
          python mysql-postgresql-converter/db_converter.py gitlab_ci.sql.tmp gitlab_ci.sql.tmp2
          ed -s gitlab_ci.sql.tmp2 < mysql-postgresql-converter/move_drop_indexes.ed

          # Filter to only include INSERT statements
          grep "^\(START\|SET\|INSERT\|COMMIT\)" gitlab_ci.sql.tmp2 > gitlab_ci.sql
          ```

[mysql-postgresql-converter]: https://github.com/gitlabhq/mysql-postgresql-converter

### Part II: GitLab CE (or EE)

#### 1. Ensure GitLab is updated

Your GitLab CE or EE installation **must be version 8.0**. If it's not, follow
the [update guide](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/7.14-to-8.0.md).

#### 2. Stop GitLab

Before you can migrate data you need to stop the GitLab service first:

    sudo service gitlab stop

#### 3. Create a backup

This migration poses a **significant risk** of breaking your GitLab
installation. Create a backup before proceeding:

    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

#### 4. Copy secret tokens from CI

The `secrets.yml` file stores encryption keys for secure variables.

You need to copy the contents of GitLab CI's `config/secrets.yml` file to the
same file in GitLab CE:

    sudo cp /home/gitlab_ci/gitlab-ci/config/secrets.yml /home/git/gitlab/config/secrets.yml
    sudo chown git:git /home/git/gitlab/config/secrets.yml
    sudo chown 0600 /home/git/gitlab/config/secrets.yml

#### 5. New configuration options for `gitlab.yml`

There are new configuration options available for `gitlab.yml`. View them with
the command below and apply them manually to your current `gitlab.yml`:

```sh
git diff origin/7-14-stable:config/gitlab.yml.example origin/8-0-stable:config/gitlab.yml.example
```

The new options include configuration settings for GitLab CI.

#### 6. Copy build logs

You need to copy the contents of GitLab CI's `builds/` directory to the
corresponding directory in GitLab CE or EE:

    sudo rsync -av /home/gitlab_ci/gitlab-ci/builds /home/git/gitlab/builds
    sudo chown -R git:git /home/git/gitlab/builds

The build logs are usually quite big so it may take a significant amount of
time.

#### 7. Import GitLab CI database

Now you'll import the GitLab CI database dump that you [created
earlier](#5-create-a-database-dump) into the GitLab CE or EE database:

    sudo mv /home/gitlab_ci/gitlab-ci/gitlab_ci.sql /home/git/gitlab/gitlab_ci.sql
    sudo chown git:git /home/git/gitlab/gitlab_ci.sql
    sudo -u git -H bundle exec rake ci:migrate CI_DUMP=/home/git/gitlab/gitlab_ci.sql RAILS_ENV=production

This task will:

1. Delete data from all existing CI tables
1. Import data from database dump
1. Fix database auto-increments
1. Fix tags assigned to Builds and Runners
1. Fix services used by CI

#### 8. Start GitLab

You can start GitLab CI (or EE) now and see if everything is working:

    sudo service gitlab start

### Part III: Finishing Up

#### 1. Update Nginx configuration

To ensure that your existing CI runners are able to communicate with the
migrated installation, and that existing build triggers still work, you'll need
to update your Nginx configuration to redirect requests for the old locations to
the new ones.

Edit `/etc/nginx/sites-available/gitlab_ci` and paste:

```nginx
# GITLAB CI
server {
  listen 80 default_server;         # e.g., listen 192.168.1.1:80;
  server_name YOUR_CI_SERVER_FQDN;  # e.g., server_name source.example.com;

  access_log  /var/log/nginx/gitlab_ci_access.log;
  error_log   /var/log/nginx/gitlab_ci_error.log;

  # expose API to fix runners
  location /api {
    proxy_read_timeout    300;
    proxy_connect_timeout 300;
    proxy_redirect        off;
    proxy_set_header      X-Real-IP $remote_addr;

    # You need to specify your DNS servers that are able to resolve YOUR_GITLAB_SERVER_FQDN
    resolver 8.8.8.8 8.8.4.4;
    proxy_pass $scheme://YOUR_GITLAB_SERVER_FQDN/ci$request_uri;
  }

  # expose build endpoint to allow trigger builds
  location ~ ^/projects/\d+/build$ {
    proxy_read_timeout    300;
    proxy_connect_timeout 300;
    proxy_redirect        off;
    proxy_set_header      X-Real-IP $remote_addr;

    # You need to specify your DNS servers that are able to resolve YOUR_GITLAB_SERVER_FQDN
    resolver 8.8.8.8 8.8.4.4;
    proxy_pass $scheme://YOUR_GITLAB_SERVER_FQDN/ci$request_uri;
  }

  # redirect all other CI requests
  location / {
    return 301 $scheme://YOUR_GITLAB_SERVER_FQDN/ci$request_uri;
  }

  # adjust this to match the largest build log your runners might submit,
  # set to 0 to disable limit
  client_max_body_size 10m;
}
```

Make sure you substitute these placeholder values with your real ones:

1. `YOUR_CI_SERVER_FQDN`: The existing public-facing address of your GitLab CI
   install (e.g., `ci.gitlab.com`).
1. `YOUR_GITLAB_SERVER_FQDN`: The current public-facing address of your GitLab
   CE (or EE) install (e.g., `gitlab.com`).

**Make sure not to remove the `/ci$request_uri` part. This is required to properly forward the requests.**

You should also make sure that you can:

1. `curl https://YOUR_GITLAB_SERVER_FQDN/` from your previous GitLab CI server.
1. `curl https://YOUR_CI_SERVER_FQDN/` from your GitLab CE (or EE) server.

#### 2. Check Nginx configuration

    sudo nginx -t

#### 3. Restart Nginx

    sudo /etc/init.d/nginx restart

#### 4. Done!

If everything went well you should be able to access your migrated CI install by
visiting `https://gitlab.example.com/ci/`.

If you visit the old GitLab CI address, you should be redirected to the new one.

**Enjoy!**
