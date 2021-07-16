---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
comments: false
---

# Universal update guide for patch versions of source installations **(FREE SELF)**

## Select Version to Install

Make sure you view [this update guide](https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/update/patch_versions.md) from the tag (version) of GitLab you would like to install.
In most cases this should be the highest numbered production tag (without `rc` in it).
You can select the tag in the version dropdown in the top left corner of GitLab (below the menu bar).

### 0. Backup

It's useful to make a backup just in case things go south. Depending on the installation method, backup commands vary. See the [backing up and restoring GitLab](../raketasks/backup_restore.md) documentation.

### 1. Stop server

```shell
sudo service gitlab stop
```

### 2. Get latest code for the stable branch

In the commands below, replace `LATEST_TAG` with the latest GitLab tag you want
to update to, for example `v8.0.3`. Use `git tag -l 'v*.[0-9]' --sort='v:refname'`
to see a list of all tags. Make sure to update patch versions only (check your
current version with `cat VERSION`).

```shell
cd /home/git/gitlab

sudo -u git -H git fetch --all
sudo -u git -H git checkout -- Gemfile.lock db/structure.sql locale
sudo -u git -H git checkout LATEST_TAG -b LATEST_TAG
```

### 3. Install libraries, migrations, etc

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

# Compile GetText PO files
# Internationalization was added in `v9.2.0` so this command is only
# required for versions equal or major to it.
sudo -u git -H bundle exec rake gettext:compile RAILS_ENV=production

# Clean up assets and cache
sudo -u git -H bundle exec rake yarn:install gitlab:assets:clean gitlab:assets:compile cache:clear RAILS_ENV=production NODE_ENV=production NODE_OPTIONS="--max_old_space_size=4096"
```

### 4. Update GitLab Workhorse to the corresponding version

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:workhorse:install[/home/git/gitlab-workhorse]" RAILS_ENV=production
```

### 5. Update Gitaly to the corresponding version

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake "gitlab:gitaly:install[/home/git/gitaly,/home/git/repositories]" RAILS_ENV=production
```

### 6. Update GitLab Shell to the corresponding version

```shell
cd /home/git/gitlab-shell

sudo -u git -H git fetch --all --tags
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_SHELL_VERSION) -b v$(</home/git/gitlab/GITLAB_SHELL_VERSION)
sudo -u git -H make build
```

### 7. Update GitLab Pages to the corresponding version (skip if not using pages)

```shell
cd /home/git/gitlab-pages

sudo -u git -H git fetch --all --tags
sudo -u git -H git checkout v$(</home/git/gitlab/GITLAB_PAGES_VERSION)
sudo -u git -H make
```

### 8. Install/Update `gitlab-elasticsearch-indexer` **(PREMIUM SELF)**

Please follow the [install instruction](../integration/elasticsearch.md#installing-elasticsearch).

### 9. Start application

```shell
sudo service gitlab start
sudo service nginx restart
```

### 10. Check application status

Check if GitLab and its environment are configured correctly:

```shell
cd /home/git/gitlab

sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

To make sure you didn't miss anything run a more thorough check with:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

If all items are green, then congratulations upgrade complete!

### 11. Make sure background migrations are finished

[Check the status of background migrations](../user/admin_area/monitoring/background_migrations.md#check-the-status-of-background-migrations)
and make sure they are finished.
