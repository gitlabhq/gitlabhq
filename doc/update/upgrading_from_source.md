---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrading self-compiled instances
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

Upgrading self-compiled instances to a later version of GitLab requires several steps, many specific to self-compiled
installations.

If you are changing from GitLab Community Edition to GitLab Enterprise Edition, see
the [Upgrading from CE to EE](upgrading_from_ce_to_ee.md) documentation.

## Upgrading to a new major version

Major versions introduce backwards-incompatible changes. You should first upgrade to the latest available minor version
of your current major version. Follow the [Upgrade Recommendations](../policy/maintenance.md#upgrade-recommendations)
to identify the ideal upgrade path.

Before upgrading to a new major version, you should ensure that any background
migration jobs from previous releases have been completed. To see the current size of the `background_migration` queue,
[Check for background migrations before upgrading](background_migrations.md).

## Upgrade a self-compiled instance

To upgrade a self-compiled GitLab instance:

1. Consult changes for different versions of GitLab to ensure compatibility before upgrading:
   - [GitLab 17 changes](versions/gitlab_17_changes.md)
   - [GitLab 16 changes](versions/gitlab_16_changes.md)
   - [GitLab 15 changes](versions/gitlab_15_changes.md)
1. Check for [background migrations](background_migrations.md). All migrations must finish running before each upgrade.
1. [Create a backup](#create-a-backup).
1. [Stop GitLab](#stop-gitlab).
1. [Update Ruby](#update-ruby).
1. [Update Node.js](#update-nodejs).
1. [Update Go](#update-go).
1. [Update Git](#update-git).
1. [Update PostgreSQL](#update-postgresql).
1. [Update the GitLab codebase](#update-the-gitlab-codebase).
1. [Update configuration files](#update-configuration-files).
1. [Install libraries and run migrations](#install-libraries-and-run-migrations).
1. [Update GitLab Shell](#update-gitlab-shell).
1. [Update GitLab Workhorse](#update-gitlab-workhorse).
1. [Update Gitaly](#update-gitaly).
1. [Update GitLab Pages](#update-gitlab-pages).

After you've upgraded:

1. [Start GitLab and NGINX](#start-gitlab-and-nginx).
1. [Check GitLab status](#check-gitlab-status).

### Create a backup

Prerequisites:

- Make sure `rsync` is installed.

Perform the backup:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### Stop GitLab

```shell
# For systems running systemd
sudo systemctl stop gitlab.target

# For systems running SysV init
sudo service gitlab stop
```

### Update Ruby

In GitLab 17.5 and later, only Ruby 3.2.x is supported. Be sure to upgrade if necessary.
You can check which version of Ruby you have with:

```shell
ruby -v
```

[Install Ruby](https://www.ruby-lang.org/en/documentation/installation/).

### Update Node.js

To check the minimum required Node.js version, see [Node.js versions](../install/installation.md#software-requirements).

GitLab also requires Yarn `>= v1.10.0` to manage JavaScript dependencies.

To update Yarn for Debian or Ubuntu:

```shell
sudo apt-get remove yarn

npm install --global yarn
```

For more information, see the [Yarn website](https://classic.yarnpkg.com/en/docs/install).

### Update Go

To check the minimum required Go version, see [Go versions](../install/installation.md#software-requirements).

You can check which version you are running:

```shell
go version
```

Download and install Go. For example, for 64-bit Linux:

```shell
# Remove former Go installation folder
sudo rm -rf /usr/local/go

curl --remote-name --location --progress-bar "https://go.dev/dl/go1.22.5.linux-amd64.tar.gz"
echo '904b924d435eaea086515bc63235b192ea441bd8c9b198c507e85009e6e4c7f0  go1.22.5.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.22.5.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,gofmt} /usr/local/bin/
rm go1.22.5.linux-amd64.tar.gz
```

### Update Git

To check you are running the minimum required Git version, see
[Git versions](../install/installation.md#software-requirements).

Use the [Git version provided by Gitaly](https://gitlab.com/gitlab-org/gitaly/-/issues/2729) that:

- Is always at the version required by GitLab.
- May contain custom patches required for proper operation.

```shell
# Install dependencies
sudo apt-get install -y libcurl4-openssl-dev libexpat1-dev gettext libz-dev libssl-dev libpcre2-dev build-essential

# Clone the Gitaly repository
git clone https://gitlab.com/gitlab-org/gitaly.git -b <X-Y-stable> /tmp/gitaly

# Compile and install Git
cd /tmp/gitaly
sudo make git GIT_PREFIX=/usr/local
```

Replace `<X-Y-stable>` with the stable branch that matches the GitLab version you want to
install. For example, if you want to install GitLab 16.7, use the branch name `16-7-stable`.

Remember to set `git -> bin_path` to `/usr/local/bin/git` in `config/gitlab.yml`.

### Update PostgreSQL

The latest version of GitLab might depend on a more recent PostgreSQL version
than what you are running. You may also have to enable some
extensions. For more information, see the
[PostgreSQL requirements](../install/requirements.md#postgresql)

WARNING:
GitLab 17.0 requires PostgreSQL 14. GitLab 17.5 is compatible with up to PostgreSQL 16.

To upgrade PostgreSQL, refer to its [documentation](https://www.postgresql.org/docs/11/upgrading.html).

### Update the GitLab codebase

To update your clone of the GitLab codebase:

1. Fetch repository metadata:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git fetch --all --prune
   sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
   ```

1. Check out the branch for the version you want to upgrade to:

   - For GitLab Community Edition:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H git checkout <BRANCH>
     ```

   - For GitLab Enterprise Edition:

     ```shell
     cd /home/git/gitlab

     sudo -u git -H git checkout <BRANCH-ee>
     ```

### Update configuration files

To update configuration files for an upgrade, apply new configuration options for:

- `gitlab.yml`
- `database.yml`
- NGINX (or Apache)
- SMTP
- systemd
- SysV

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

> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/119139) in GitLab 16.0 to have `ci:` section in `config/database.yml.postgresql`.

There might be new configuration options available for
[`database.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/database.yml.postgresql).

1. View possible new configuration:

   ```shell
   cd /home/git/gitlab
   git diff origin/PREVIOUS_BRANCH:config/database.yml.postgresql origin/BRANCH:config/database.yml.postgresql
   ```

1. Apply new configuration manually to your current `database.yml`:

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

1. Make sure you have the required [PostgreSQL extensions](../install/requirements.md#postgresql).
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

   # Run database migrations
   sudo -u git -H bundle exec rake db:migrate RAILS_ENV=production

   # Update node dependencies and recompile assets
   sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"

   # Clean up cache
   sudo -u git -H bundle exec rake cache:clear RAILS_ENV=production
   ```

### Update GitLab Shell

To update GitLab Shell:

```shell
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

### Update GitLab Workhorse

Install and compile GitLab Workhorse:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

### Update Gitaly

Upgrade Gitaly servers to the newer version before upgrading the application server. This prevents the gRPC client
on the application server from sending RPCs that the old Gitaly version does not support.

If Gitaly is located on its own server, or you use Gitaly Cluster, see [Zero-downtime upgrades](zero_downtime.md).

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

Install and compile GitLab Pages:

```shell
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### Start GitLab and NGINX

```shell
# For systems running systemd
sudo systemctl start gitlab.target
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service gitlab start
sudo service nginx restart
```

### Check GitLab status

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

If you have more than one backup `*.tar` file, add `BACKUP=timestamp_of_backup` to the above.
