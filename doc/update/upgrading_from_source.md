---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrading Community Edition and Enterprise Edition from source **(FREE SELF)**

Make sure you view this upgrade guide from the branch (version) of GitLab you
would like to install (for example, `11.8`). You can select the required version of documentation in the dropdown list in the upper-right corner of GitLab documentation page.

In each of the following examples, replace `BRANCH` with the branch of the version you upgrading to (for example, `11-8-stable` for `11.8`). Replace `PREVIOUS_BRANCH` with the
branch for the version you are upgrading from (for example, `11-7-stable` for `11.7`).

If the highest number stable branch is unclear check the
[GitLab Blog](https://about.gitlab.com/blog/archives.html) for installation
guide links by version.

If you are changing from GitLab Community Edition to GitLab Enterprise Edition, see
the [Upgrading from CE to EE](upgrading_from_ce_to_ee.md) documentation.

## Upgrading to a new major version

Major versions are reserved for backwards incompatible changes. We recommend that
you first upgrade to the latest available minor version of your current major version.
Follow the [Upgrade Recommendations](../policy/maintenance.md#upgrade-recommendations)
to identify the ideal upgrade path.

Before upgrading to a new major version, you should ensure that any background
migration jobs from previous releases have been completed. To see the current size of the `background_migration` queue,
[Check for background migrations before upgrading](background_migrations.md).

## Guidelines for all versions

This section contains all the steps necessary to upgrade Community Edition or
Enterprise Edition, regardless of the version you are upgrading to. Version
specific guidelines (should there be any) are covered separately.

### 1. Backup

If you installed GitLab from source, make sure `rsync` is installed.

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### 2. Stop server

```shell
# For systems running systemd
sudo systemctl stop gitlab.target

# For systems running SysV init
sudo service gitlab stop
```

### 3. Update Ruby

From GitLab 15.10, we only support Ruby 3.0.x and dropped support for Ruby 2.7. Be sure to upgrade if necessary.
You can check which version you are running with `ruby -v`.

[Install Ruby](https://www.ruby-lang.org/en/documentation/installation/).

### 4. Update Node.js

To check the minimum required Node.js version, see [Node.js versions](../install/installation.md#software-requirements).

GitLab also requires the use of Yarn `>= v1.10.0` to manage JavaScript
dependencies.

In Debian or Ubuntu:

```shell
sudo apt-get remove yarn

npm install --global yarn
```

More information can be found on the [Yarn website](https://classic.yarnpkg.com/en/docs/install).

### 5. Update Go

To check the minimum required Go version, see [Go versions](../install/installation.md#software-requirements).

You can check which version you are running with `go version`.

Download and install Go (for Linux, 64-bit):

```shell
# Remove former Go installation folder
sudo rm -rf /usr/local/go

curl --remote-name --location --progress-bar "https://go.dev/dl/go1.18.8.linux-amd64.tar.gz"
echo '4d854c7bad52d53470cf32f1b287a5c0c441dc6b98306dea27358e099698142a  go1.18.8.linux-amd64.tar.gz' | shasum -a256 -c - && \
  sudo tar -C /usr/local -xzf go1.18.8.linux-amd64.tar.gz
sudo ln -sf /usr/local/go/bin/{go,gofmt} /usr/local/bin/
rm go1.18.8.linux-amd64.tar.gz
```

### 6. Update Git

To check you are running the minimum required Git version, see
[Git versions](../install/installation.md#software-requirements).

From GitLab 13.6, we recommend you use the
[Git version provided by Gitaly](https://gitlab.com/gitlab-org/gitaly/-/issues/2729)
that:

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
install. For example, if you want to install GitLab 13.6, use the branch name `13-6-stable`.

Remember to set `git -> bin_path` to `/usr/local/bin/git` in `config/gitlab.yml`.

### 7. Update PostgreSQL

WARNING:
GitLab 14.0 requires at least PostgreSQL 12.

The latest version of GitLab might depend on a more recent PostgreSQL version
than what you are running. You may also have to enable some
extensions. For more information, see the
[PostgreSQL requirements](../install/requirements.md#postgresql-requirements)

To upgrade PostgreSQL, refer to its [documentation](https://www.postgresql.org/docs/11/upgrading.html).

### 8. Get latest code

```shell
cd /home/git/gitlab

sudo -u git -H git fetch --all --prune
sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
```

For GitLab Community Edition:

```shell
cd /home/git/gitlab

sudo -u git -H git checkout BRANCH
```

OR

For GitLab Enterprise Edition:

```shell
cd /home/git/gitlab

sudo -u git -H git checkout BRANCH-ee
```

### 9. Update configuration files

#### New configuration options for `gitlab.yml`

There might be configuration options available for [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/gitlab.yml.example)).
View them with the command below and apply them manually to your current `gitlab.yml`:

```shell
cd /home/git/gitlab

git diff origin/PREVIOUS_BRANCH:config/gitlab.yml.example origin/BRANCH:config/gitlab.yml.example
```

#### New configuration options for `database.yml`

There might be configuration options available for [`database.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/database.yml.postgresql).
View them with the command below and apply them manually to your current `database.yml`:

```shell
cd /home/git/gitlab

git diff origin/PREVIOUS_BRANCH:config/database.yml.postgresql origin/BRANCH:config/database.yml.postgresql
```

#### NGINX configuration

Ensure you're still up-to-date with the latest NGINX configuration changes:

```shell
cd /home/git/gitlab

# For HTTPS configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab-ssl origin/BRANCH:lib/support/nginx/gitlab-ssl

# For HTTP configurations
git diff origin/PREVIOUS_BRANCH:lib/support/nginx/gitlab origin/BRANCH:lib/support/nginx/gitlab
```

If you are using Strict-Transport-Security in your installation, you must enable it in your
NGINX configuration to continue using it. This is because the GitLab application no longer
sets it.

If you are using Apache instead of NGINX see the updated [Apache templates](https://gitlab.com/gitlab-org/gitlab-recipes/tree/master/web-server/apache).
Also because Apache does not support upstreams behind Unix sockets you
must let GitLab Workhorse listen on a TCP port. You can do this
via [`/etc/default/gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/init.d/gitlab.default.example#L38).

#### SMTP configuration

If you're installing from source and use SMTP to deliver mail, you must
add the following line to `config/initializers/smtp_settings.rb`:

```ruby
ActionMailer::Base.delivery_method = :smtp
```

See [`smtp_settings.rb.sample`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/config/initializers/smtp_settings.rb.sample#L13) as an example.

#### Configure systemd units

If using the SysV init script, see [Configure SysV init script](#configure-sysv-init-script).

Check if the systemd units have been updated:

```shell
cd /home/git/gitlab

git diff origin/PREVIOUS_BRANCH:lib/support/systemd origin/BRANCH:lib/support/systemd
```

Copy them over:

```shell
sudo mkdir -p /usr/local/lib/systemd/system
sudo cp lib/support/systemd/* /usr/local/lib/systemd/system/
sudo systemctl daemon-reload
```

#### Configure SysV init script

If using systemd units, see [Configure systemd units](#configure-systemd-units).

There might be new configuration options available for
[`gitlab.default.example`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/support/init.d/gitlab.default.example).
View them with the command below and apply them manually to your current `/etc/default/gitlab`:

```shell
cd /home/git/gitlab

git diff origin/PREVIOUS_BRANCH:lib/support/init.d/gitlab.default.example origin/BRANCH:lib/support/init.d/gitlab.default.example
```

Ensure you're still up-to-date with the latest init script changes:

```shell
cd /home/git/gitlab

sudo cp lib/support/init.d/gitlab /etc/init.d/gitlab
```

If you are using the init script on a system running systemd as init, because you have not switched to native systemd units yet, run:

```shell
sudo systemctl daemon-reload
```

### 10. Install libraries, migrations, etc

Make sure you have the required
[PostgreSQL extensions](../install/requirements.md#postgresql-requirements),
then proceed to install the needed libraries:

```shell
cd /home/git/gitlab

# If you haven't done so during installation or a previous upgrade already
sudo -u git -H bundle config set --local deployment 'true'
sudo -u git -H bundle config set --local without 'development test mysql aws kerberos'

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

### 11. Update GitLab Shell

```shell
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

### 12. Update GitLab Workhorse

Install and compile GitLab Workhorse.

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

NOTE:
If you get any errors concerning Rack attack, see the [13.1](index.md#custom-rack-attack-initializers)
specific changes.

### 13. Update Gitaly

If Gitaly is located on its own server, or you use Gitaly Cluster, see [Gitaly or Gitaly Cluster](zero_downtime.md#gitaly-or-gitaly-cluster)
on the Zero downtime upgrades page.

#### Compile Gitaly

```shell
# Fetch Gitaly source with Git and compile with Go
cd /home/git/gitlab
sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

### 14. Update GitLab Pages

#### Only needed if you use GitLab Pages

Install and compile GitLab Pages. GitLab Pages uses
[GNU Make](https://www.gnu.org/software/make/).
If you are not using Linux you may have to run `gmake` instead of
`make` below.

```shell
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags --prune
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### 15. Start application

```shell
# For systems running systemd
sudo systemctl start gitlab.target
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service gitlab start
sudo service nginx restart
```

### 16. Check application status

Check if GitLab and its environment are configured correctly:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

To make sure you didn't miss anything run a more thorough check:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

If all items are green, then congratulations, the upgrade is complete!

### 17. Upgrade the product documentation

This is an optional step. If you [installed the product documentation](../install/installation.md#install-the-product-documentation),
see how to [upgrade to a later version](../administration/docs_self_host.md#upgrade-the-product-documentation-to-a-later-version).

## Version specific changes

Upgrading versions might need some manual intervention. For more information,
[check the version you are upgrading to](index.md#version-specific-upgrading-instructions)
for additional steps required for all GitLab installations, and for
steps that apply to self-compiled (source) installations.

## Troubleshooting

### 1. Revert the code to the previous version

To revert to a previous version, you must follow the upgrading guides
for the previous version.

For example, if you have upgraded to GitLab 12.6 and want to revert back to
12.5, follow the guides for upgrading from 12.4 to 12.5. You can
use the version dropdown list at the top of the page to select the right version.

When reverting, you should **not** follow the database migration guides, as the
backup has already been migrated to the previous version.

### 2. Restore from the backup

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

If you have more than one backup `*.tar` file, add `BACKUP=timestamp_of_backup` to the above.
