---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Convert a self-compiled CE instance to EE
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can convert an existing self-compiled instance from Community Edition (CE) to Enterprise Edition (EE).

These instructions assume you have a correctly configured and tested self-compiled installation of GitLab CE.

## Convert from CE to EE

In the following instructions, replace:

- `EE_BRANCH` with the EE branch for the version you are using. EE branch names use the format `major-minor-stable-ee`.
  For example, `17-7-stable-ee`.
- `CE_BRANCH` with the Community Edition branch. CE branch names use the format `major-minor-stable`.
  For example, `17-7-stable`.

### Backup

To back up GitLab:

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### Stop GitLab server

To stop the GitLab server:

```shell
sudo service gitlab stop
```

### Get the EE code

To get the EE code:

```shell
cd /home/git/gitlab
sudo -u git -H git remote add -f ee https://gitlab.com/gitlab-org/gitlab.git
sudo -u git -H git checkout EE_BRANCH
```

### Install libraries and run migrations

To install libraries and run migrations:

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

### Install `gitlab-elasticsearch-indexer`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

To install `gitlab-elasticsearch-indexer`, follow the
[install instruction](../integration/advanced_search/elasticsearch.md#install-an-elasticsearch-or-aws-opensearch-cluster).

### Start the application

To start the application:

```shell
sudo service gitlab start
sudo service nginx restart
```

### Check application status

Check if GitLab and its environment are configured correctly:

```shell
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

To make sure you didn't miss anything, run a more thorough check:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

If all items are green, then congratulations upgrade complete!

## Revert back to CE

If you encounter problems converting to EE and want to revert back to CE:

1. Revert the code to the previous version:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H git checkout CE_BRANCH
   ```

1. Restore from the backup:

   ```shell
   cd /home/git/gitlab
   sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
   ```
