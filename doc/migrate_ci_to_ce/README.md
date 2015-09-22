## Migrate GitLab CI to GitLab CE or EE

Beginning with version 8.0 of GitLab Community Edition (CE) and Enterprise
Edition (EE), GitLab CI is no longer its own application, but is instead built
into the CE and EE applications.

This guide will detail the process of migrating your CI installation and data
into your GitLab CE or EE installation.

### Before we begin

**You need to have a working installation of GitLab CI version 8.0 to perform
this migration. The older versions are not supported and will most likely break
this migration procedure.**

This migration cannot be performed online and takes a significant amount of
time. Make sure to plan ahead.

If you are running a version of GitLab CI prior to 8.0 please follow the
appropriate [update guide](https://gitlab.com/gitlab-org/gitlab-ci/tree/master/doc/update/)
before proceeding.

The migration is divided into four parts and covers both manual and Omnibus
installations:

1. [GitLab CI](#part-i-gitlab-ci)
1. [Gitlab CE (or EE)](#part-ii-gitlab-ce-or-ee)
1. [Nginx configuration](#part-iii-nginx-configuration)
1. [Finishing Up](#part-iv-finishing-up)

### Part I: GitLab CI

#### 1. Stop GitLab CI

    # Manual installation
    sudo service gitlab_ci stop

    # Omnibus installation
    sudo gitlab-ctl stop ci-unicorn ci-sidekiq

#### 2. Create a backup

The migration procedure modifies the structure of the CI database. If something
goes wrong, you will not be able to revert to a previous version without a
backup.

If your GitLab CI installation uses **MySQL** and your GitLab CE (or EE)
installation uses **PostgreSQL** you'll need to convert the CI database by
setting a `MYSQL_TO_POSTGRESQL` flag.

If you use the Omnibus package you most likely use **PostgreSQL** on both GitLab
CE (or EE) and CI.

You can check which database each install is using by viewing their
database configuration files:

    cat /home/gitlab_ci/gitlab-ci/config/database.yml
    cat /home/git/gitlab/config/database.yml

- If both applications use the same database `adapter`, create the backup with
  this command:

        # Manual installation
        cd /home/gitlab_ci/gitlab-ci
        sudo -u gitlab_ci -H bundle exec rake backup:create RAILS_ENV=production

        # Omnibus installation
        sudo gitlab-ci-rake backup:create

- If CI uses MySQL, and CE (or EE) uses PostgreSQL, create the backup with this
  command (note the `MYSQL_TO_POSTGRESQL` flag):

        # Manual installation
        cd /home/gitlab_ci/gitlab-ci
        sudo -u gitlab_ci -H bundle exec rake backup:create RAILS_ENV=production MYSQL_TO_POSTGRESQL=1

        # Omnibus installation
        sudo gitlab-ci-rake backup:create MYSQL_TO_POSTGRESQL=1

#### 3. Remove cronjob

**Note:** This step is only required for **manual installations**. Omnibus users
can [skip to the next step](#part-ii-gitlab-ce-or-ee).

    # Manual installation
    cd /home/gitlab_ci/gitlab-ci
    sudo -u gitlab_ci -H bundle exec whenever --clear-crontab

### Part II: GitLab CE (or EE)

#### 1. Ensure GitLab is updated

Your GitLab CE or EE installation **must be version 8.0**. If it's not, follow
the [update guide](https://gitlab.com/gitlab-org/gitlab-ce/blob/master/doc/update/7.14-to-8.0.md)
before proceeding.

If you use the Omnibus packages simply run `apt-get upgrade` to install the
latest version.

#### 2. Prevent CI usage during the migration process

As an administrator, go to **Admin Area** -> **Settings**, and under **Continuous
Integration** uncheck **Disable to prevent CI usage until rake ci:migrate is run
(8.0 only)**.

This will disable the CI integration and prevent users from creating CI projects
until the migration process is completed.

#### 3. Stop GitLab

Before you can migrate data you need to stop the GitLab service first:

    # Manual installation
    sudo service gitlab stop

    # Omnibus installation
    sudo gitlab-ctl stop unicorn sidekiq

#### 4. Create a backup

This migration poses a **significant risk** of breaking your GitLab
installation. Create a backup before proceeding:

    # Manual installation
    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production

    # Omnibus installation
    sudo gitlab-rake gitlab:backup:create

It's possible to speed up backup creation by skipping repositories and uploads:

    # Manual installation
    cd /home/git/gitlab
    sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production SKIP=repositories,uploads

    # Omnibus installation
    sudo gitlab-rake gitlab:backup:create SKIP=repositories,uploads

#### 5. Copy secret tokens from CI

The `secrets.yml` file stores encryption keys for secure variables.

- **Manual installations** need to copy the contents of GitLab CI's
  `config/secrets.yml` file to the same file in GitLab CE:

    ```bash
    # Manual installation
    sudo cp /home/gitlab_ci/gitlab-ci/config/secrets.yml /home/git/gitlab/config/secrets.yml
    sudo chown git:git /home/git/gitlab/config/secrets.yml
    sudo chown 0600 /home/git/gitlab/config/secrets.yml
    ```

- **Omnibus installations** where GitLab CI and CE (or EE) are on the same
  server don't need to do anything further, because the secrets are stored in
  `/etc/gitlab/gitlab-secrets.json`.

- **Omnibus installations** where GitLab CI is on a different server than CE (or
  EE) will need to:
    1. On the CI server, copy the `db_key_base` value from
       `/etc/gitlab/gitlab-secrets.json`
    1. On the CE (or EE) server, add `gitlab_ci['db_key_base'] =
       "VALUE_FROM_ABOVE"` to the `/etc/gitlab/gitlab.rb` file and run `sudo
       gitlab-ctl reconfigure`

#### 6. New configuration options for `gitlab.yml`

**Note:** This step is only required for **manual installations**. Omnibus users
can [skip to the next step](#7-copy-backup-from-gitlab-ci).

There are new configuration options available for `gitlab.yml`. View them with
the command below and apply them manually to your current `gitlab.yml`:

    git diff origin/7-14-stable:config/gitlab.yml.example origin/8-0-stable:config/gitlab.yml.example

The new options include configuration settings for GitLab CI.

#### 7. Copy backup from GitLab CI

```bash
# Manual installation
sudo cp -v /home/gitlab_ci/gitlab-ci/tmp/backups/*_gitlab_ci_backup.tar /home/git/gitlab/tmp/backups
sudo chown git:git /home/git/gitlab/tmp/backups/*_gitlab_ci_backup.tar

# Omnibus installation
sudo cp -v /var/opt/gitlab/ci-backups/*_gitlab_ci_backup.tar /var/opt/gitlab/backups/
sudo chown git:git /var/opt/gitlab/backups/*_gitlab_ci_backup.tar
```

If moving across the servers you can use `scp`.
However, this requires you to provide an authorized key or password to login to
the GitLab CE (or EE) server from the CI server. You can try to use ssh-agent
from your local machine to have that: login to your GitLab CI server using
`ssh -A`.

```bash
# Manual installation
scp /home/gitlab_ci/gitlab-ci/tmp/backups/*_gitlab_ci_backup.tar root@gitlab.example.com:/home/git/gitlab/tmp/backup

# Omnibus installation
scp /var/opt/gitlab/ci-backups/*_gitlab_ci_backup.tar root@gitlab.example.com:/var/opt/gitlab/backups/
```

#### 8. Import GitLab CI backup

Now you'll import the GitLab CI database dump that you created earlier into the
GitLab CE or EE database:

    # Manual installation
    sudo -u git -H bundle exec rake ci:migrate RAILS_ENV=production

    # Omnibus installation
    sudo gitlab-rake ci:migrate

This task will take some time.

This migration task automatically re-enables the CI setting that you
[disabled earlier](#2-prevent-ci-usage-during-the-migration-process).

#### 9. Start GitLab

You can start GitLab CE (or EE) now and see if everything is working:

    # Manual installation
    sudo service gitlab start

    # Omnibus installation
    sudo gitlab-ctl restart unicorn sidekiq

### Part III: Nginx configuration

This section is only required for **manual installations**. Omnibus users can
[skip to the final step](#part-iv-finishing-up).

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

**Make sure not to remove the `/ci$request_uri` part. This is required to
properly forward the requests.**

You should also make sure that you can:

1. `curl https://YOUR_GITLAB_SERVER_FQDN/` from your previous GitLab CI server.
1. `curl https://YOUR_CI_SERVER_FQDN/` from your GitLab CE (or EE) server.

#### 2. Check Nginx configuration

    sudo nginx -t

#### 3. Restart Nginx

    sudo /etc/init.d/nginx restart

### Part IV: Finishing Up

If everything went well you should be able to access your migrated CI install by
visiting `https://gitlab.example.com/ci/`. If you visit the old GitLab CI
address, you should be redirected to the new one.

**Enjoy!**

### Troubleshooting

#### Restore from backup

If something went wrong and you need to restore a backup, consult the [Backup
restoration](../raketasks/backup_restore.md) guide.
