---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade self-compiled instances
description: Upgrade a single-node self-compiled instance.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Upgrade a self-compiled instance to a later version of GitLab.

## Prerequisites

Before you upgrade:

1. You must [read required information and perform required steps](plan_your_upgrade.md).
1. Review the [software requirements](../install/self_compiled/_index.md#software-requirements) for Ruby, Node.js, Go,
   and PostgreSQL.

## Upgrade a self-compiled instance

To upgrade a self-compiled instance:

1. Consider [turning on maintenance mode](../administration/maintenance_mode/_index.md) during the upgrade.
1. Pause [running CI/CD pipelines and jobs](plan_your_upgrade.md#pause-cicd-pipelines-and-jobs).
1. [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/) to the same version as your target GitLab version.
1. Upgrade GitLab by following the instructions on this page.

After you upgrade:

1. Unpause [running CI/CD pipelines and jobs](plan_your_upgrade.md#pause-cicd-pipelines-and-jobs).
1. If enabled, [turn off maintenance mode](../administration/maintenance_mode/_index.md#disable-maintenance-mode).
1. Run [upgrade health checks](plan_your_upgrade.md#run-upgrade-health-checks).

### Create a backup

Prerequisites:

- Make sure `rsync` is installed.

To create a backup:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### Stop GitLab

To stop GitLab:

```shell
# For systems running systemd
sudo systemctl stop gitlab.target

# For systems running SysV init
sudo service gitlab stop
```

### Update Ruby

If a newer version of Ruby is required, you must update Ruby:

1. To check which version of Ruby you have, run:

   ```shell
   ruby -v
   ```

1. For instructions on updating to newer versions of Ruby, see
   [Ruby installation instructions](https://www.ruby-lang.org/en/documentation/installation/).

### Update Node.js

If a newer version of Node.js is required, you must update Node.js:

1. To check which version of Node.js you have, run:

   ```shell
   node -v
   ```

1. For instructions on updating to newer versions of Node.js, see
   [Node.js download instructions](https://nodejs.org/en/download).

GitLab also requires Yarn `>= v1.10.0` to manage JavaScript dependencies. For more information, see the
[Yarn website](https://classic.yarnpkg.com/en/docs/install).

### Update Go

If a newer version of Go is required, you must update Go:

1. To check which version of Go you have, run:

   ```shell
   go version
   ```

1. For instructions on updating to newer versions of Go, see
   [Go installation instructions](https://go.dev/doc/install).

### Update Git

You should use the Git version provided by Gitaly. For more information, see
[GitLab installation instructions for Git](../install/self_compiled/_index.md#git).

### Update PostgreSQL

If a newer version of PostgreSQL is required, you must update PostgreSQL:

1. To check which version of PostgreSQL you have, run:

   ```shell
   pg_ctl --version
   ```

1. For instructions on updating to newer versions of PostgreSQL, see
   [PostgreSQL upgrading documentation](https://www.postgresql.org/docs/16/upgrading.html).
1. Make sure you have the required [PostgreSQL extensions](../install/requirements.md#postgresql).

### Update the GitLab codebase

To update your clone of the GitLab codebase:

1. Fetch repository metadata:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git fetch --all --prune
   sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
   ```

1. Check out the branch for the version you want to upgrade to:

   {{< tabs >}}

   {{< tab title="GitLab Enterprise Edition" >}}

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git checkout <BRANCH-ee>
   ```

   {{< /tab >}}

   {{< tab title="GitLab Community Edition" >}}

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git checkout <BRANCH>
   ```

   {{< /tab >}}

   {{< /tabs >}}

### Update configuration files

GitLab upgrades might require updates to the following configuration:

- `gitlab.yml`
- `database.yml`
- NGINX (or Apache)
- SMTP
- systemd
- SysV

The following sections document how to determine if configuration updates are required.

#### New configuration for `gitlab.yml`

There might be new configuration options available for
[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example).

1. View possible new configuration:

   ```shell
   cd /home/git/gitlab
   git diff origin/PREVIOUS_BRANCH:config/gitlab.yml.example origin/BRANCH:config/gitlab.yml.example
   ```

1. Apply new configuration manually to your current `gitlab.yml`.

#### New configuration for `database.yml`

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119139) in GitLab 16.0 to have `ci:` section in `config/database.yml.postgresql`.

{{< /history >}}

There might be new configuration options available for
[`database.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/database.yml.postgresql).

1. View possible new configuration:

   ```shell
   cd /home/git/gitlab
   git diff origin/PREVIOUS_BRANCH:config/database.yml.postgresql origin/BRANCH:config/database.yml.postgresql
   ```

1. Apply new configuration manually to your current `database.yml`.

#### New configuration for NGINX or Apache

Ensure you're still up-to-date with the latest NGINX configuration changes:

```shell
cd /home/git/gitlab

# For HTTPS configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab-ssl origin/BRANCH:lib/support/nginx/gitlab-ssl

# For HTTP configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab origin/BRANCH:lib/support/nginx/gitlab
```

The GitLab application no longer sets Strict-Transport-Security in your installation. You must enable it in your
NGINX configuration to continue using it.

If you are using Apache instead of NGINX, see the updated [Apache templates](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache).
Because Apache does not support upstreams behind Unix sockets, you must let GitLab Workhorse listen on a TCP port by
using [`/etc/default/gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/init.d/gitlab.default.example#L38).

#### SMTP configuration

If you use SMTP to deliver mail, you must add the following line to `config/initializers/smtp_settings.rb`:

```ruby
ActionMailer::Base.delivery_method = :smtp
```

See [`smtp_settings.rb.sample`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/smtp_settings.rb.sample#L13)
for an example.

#### Configure systemd units

1. Check if the systemd units have been updated:

   ```shell
   cd /home/git/gitlab

   git diff origin/PREVIOUS_BRANCH:lib/support/systemd origin/BRANCH:lib/support/systemd
   ```

1. Copy them over:

   ```shell
   sudo mkdir -p /usr/local/lib/systemd/system
   sudo cp lib/support/systemd/* /usr/local/lib/systemd/system/
   sudo systemctl daemon-reload
   ```

#### Configure SysV init script

There might be new configuration options available for
[`gitlab.default.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/init.d/gitlab.default.example).

1. View possible new configuration:

   ```shell
   cd /home/git/gitlab

   git diff origin/PREVIOUS_BRANCH:lib/support/init.d/gitlab.default.example origin/BRANCH:lib/support/init.d/gitlab.default.example
   ```

1. Apply them manually to your current `/etc/default/gitlab`.

Ensure you're still up-to-date with the latest init script changes:

```shell
cd /home/git/gitlab

sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

If you are using the init script on a system running systemd as init, because you have not switched to native systemd units yet, run:

```shell
sudo systemctl daemon-reload
```

### Install libraries and run migrations

To install libraries and run migrations:

1. Install the needed libraries:

   ```shell
   cd /home/git/gitlab

   # If you haven't done so during installation or a previous upgrade already
   sudo -u git -H bundle config set --local deployment 'true'
   sudo -u git -H bundle config set --local without 'development test kerberos'

   # Update gems
   sudo -u git -H bundle install

   # Optional: clean up old gems
   sudo -u git -H bundle clean
   ```

1. Run migrations:

   ```shell
   # Run database migrations
   sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production

   # Update node dependencies and recompile assets
   sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"

   # Clean up cache
   sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
   ```

### Update GitLab Shell

To update GitLab Shell, run these commands:

```shell
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

### Update GitLab Workhorse

To install and compile GitLab Workhorse, run these commands:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

### Update Gitaly

Upgrade Gitaly servers to the newer version before upgrading the application server. This prevents the gRPC client
on the application server from sending RPCs that the old Gitaly version does not support.

If Gitaly is located on its own server, or you use Gitaly Cluster (Praefect), see [Zero-downtime upgrades](zero_downtime.md).

During the build process, Gitaly [compiles and embeds Git binaries](https://gitlab.com/gitlab-org/gitaly/-/issues/6089),
which requires additional dependencies.

```shell
# Install dependencies
sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential

# Fetch Gitaly source with Git and compile with Go
cd /home/git/gitlab
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

### Update GitLab Pages

To install and compile GitLab Pages:

```shell
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### Post-upgrade steps

After you've upgraded:

1. [Start GitLab and NGINX](#start-gitlab-and-nginx).
1. [Check GitLab status](#check-gitlab-status).

#### Start GitLab and NGINX

To start GitLab and NGINX:

```shell
# For systems running systemd
sudo systemctl start gitlab.target
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service gitlab start
sudo service nginx restart
```

#### Check GitLab status

To check the status of GitLab:

1. Check if GitLab and its environment are configured correctly:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
   ```

1. To make sure you didn't miss anything, run a more thorough check:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
   ```

If all items are green, then congratulations, the upgrade is complete!

## Troubleshooting

If you have trouble during the upgrade, try some of the steps in the following sections.

### Revert the code to the previous version

To revert to a previous version, you must follow the upgrading guides for the previous version.

For example, if you have upgraded to GitLab 16.6 and want to revert back to
16.5, follow the guides for upgrading from 16.4 to 16.5.

When reverting:

- You should **not** follow the database migration guides, because the backup has already been migrated to the previous
  version.
- If you ran database migrations, you must restore a backup after the downgrade. The version of the code must be
  compatible with the version of the schema that's used. The older schema is in the backup.

### Restore from a backup

To restore from a backup:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

If you have more than one backup `*.tar` file, add `BACKUP=timestamp_of_backup` to the previous code block.
