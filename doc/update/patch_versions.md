---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Update self-compiled instances with patch versions
description: Update a single-node self-compiled instance with a patch version.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Update a self-compiled instance with a patch version.

## Prerequisites

Before you update:

1. You must [read required information and perform required steps](plan_your_upgrade.md).
1. [Back up](../administration/backup_restore/_index.md) your self-compiled instance.

## Update a self-compiled instance with a patch version

To update a self-compiled instance with a patch version:

1. Consider [turning on maintenance mode](../administration/maintenance_mode/_index.md) during the update.
1. Pause [running CI/CD pipelines and jobs](plan_your_upgrade.md#pause-cicd-pipelines-and-jobs).
1. [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/) to the same version as your target GitLab version.
1. Update GitLab by following the instructions on this page.

After you update:

1. Unpause [running CI/CD pipelines and jobs](plan_your_upgrade.md#pause-cicd-pipelines-and-jobs).
1. If enabled, [turn off maintenance mode](../administration/maintenance_mode/_index.md#disable-maintenance-mode).
1. Run [health checks](plan_your_upgrade.md#run-upgrade-health-checks).

### Stop GitLab server

To stop the GitLab server:

```shell
# For systems running systemd
sudo systemctl stop gitlab.target

# For systems running SysV init
sudo service gitlab stop
```

### Get latest code for the stable branch

In the following commands, replace `LATEST_TAG` with the GitLab tag to update to. For example, `v8.0.3`.

1. Check your current version:

   ```shell
   cat VERSION
   ```

1. Get a list of all available tags:

   ```shell
   git tag -l 'v*.[0-9]' --sort='v:refname'
   ```

1. Choose a patch version for your current major and minor version.
1. Check out the code for the patch version to use:

   ```shell
   cd /home/git/gitlab

   sudo -u git -H git fetch --all
   sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
   sudo -u git -H git checkout LATEST_TAG -b LATEST_TAG
   ```

### Install libraries and run migrations

To install libraries and run migrations, run the following commands:

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

# Clean up assets and cache
sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile cache:clear RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"
```

### Update GitLab Workhorse to the new patch version

To update GitLab Workhorse to the new patch version:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

### Update Gitaly to the new patch version

To update Gitaly to the new patch version:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

### Update GitLab Shell to the new patch version

To update GitLab Shell to the new patch version:

```shell
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION) -b v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

### Update GitLab Pages to the new patch version (if required)

If you're using GitLab Pages, update GitLab Pages to the new patch version:

```shell
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### Install or update `gitlab-elasticsearch-indexer`

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

To install or update `gitlab-elasticsearch-indexer`, follow the
[installation instruction](../integration/advanced_search/elasticsearch.md#install-an-elasticsearch-or-aws-opensearch-cluster).

### Start GitLab

To start GitLab, run the following commands:

```shell
# For systems running systemd
sudo systemctl start gitlab.target
sudo systemctl restart nginx.service

# For systems running SysV init
sudo service gitlab start
sudo service nginx restart
```

### Check GitLab and its environment

To check if GitLab and its environment are configured correctly, run:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

To make sure you didn't miss anything run a more thorough check with:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

### Make sure background migrations are finished

[Check the status of background migrations](background_migrations.md) and make sure they are finished.
