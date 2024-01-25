---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Upgrading from Community Edition to Enterprise Edition for self-compiled installations

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

NOTE:
In the past we used separate documents for upgrading from
Community Edition to Enterprise Edition. These documents can be found in the
[`doc/update` directory of Enterprise Edition's source code](https://gitlab.com/gitlab-org/gitlab/-/tree/11-8-stable-ee/doc/update).

If you want to upgrade the version only, for example 11.8 to 11.9, *without* changing the
GitLab edition you are using (Community or Enterprise), see the
[Upgrading from source](upgrading_from_source.md) documentation.

## General upgrading steps

This guide assumes you have a correctly configured and tested installation of
GitLab Community Edition. If you run into any trouble or if you have any
questions contact us at `support@gitlab.com`.

In all examples, replace `EE_BRANCH` with the Enterprise Edition branch for the
version you are using, and `CE_BRANCH` with the Community Edition branch.
Branch names use the format `major-minor-stable-ee` for Enterprise Edition, and
`major-minor-stable` for Community Edition. For example, for 11.8.0 you would
use the following branches:

- Enterprise Edition: `11-8-stable-ee`
- Community Edition: `11-8-stable`

### 0. Backup

Make a backup just in case something goes wrong:

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:backup:create RAILS_ENV=production
```

### 1. Stop server

```shell
sudo service gitlab stop
```

### 2. Get the EE code

```shell
cd /home/git/gitlab
sudo -u git -H git remote add -f ee https://gitlab.com/gitlab-org/gitlab.git
sudo -u git -H git checkout EE_BRANCH
```

### 3. Install libraries, migrations, etc

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

### 4. Install `gitlab-elasticsearch-indexer`

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

Follow the [install instruction](../integration/advanced_search/elasticsearch.md#install-elasticsearch).

### 5. Start application

```shell
sudo service gitlab start
sudo service nginx restart
```

### 6. Check application status

Check if GitLab and its environment are configured correctly:

```shell
sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production
```

To make sure you didn't miss anything run a more thorough check with:

```shell
sudo -u git -H bundle exec rake gitlab:check RAILS_ENV=production
```

If all items are green, then congratulations upgrade complete!

## Things went south? Revert to previous version (Community Edition)

### 1. Revert the code to the previous version

```shell
cd /home/git/gitlab
sudo -u git -H git checkout CE_BRANCH
```

### 2. Restore from the backup

```shell
cd /home/git/gitlab
sudo -u git -H bundle exec rake gitlab:backup:restore RAILS_ENV=production
```

## Version specific steps

Certain versions of GitLab may require you to perform additional steps when
upgrading from Community Edition to Enterprise Edition. Should such steps be
necessary, they are listed per version below.

<!--
Example:

### 11.8.0

Additional instructions here.
-->
