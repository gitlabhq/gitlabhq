---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# User management **(FREE SELF)**

GitLab provides Rake tasks for user management.

## Add user as a developer to all projects

To add a user as a developer to all projects, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_projects[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_projects[username@domain.tld] RAILS_ENV=production
```

## Add all users to all projects

To add all users to all projects, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_projects

# installation from source
bundle exec rake gitlab:import:all_users_to_all_projects RAILS_ENV=production
```

Admin users are added as maintainers.

## Add user as a developer to all groups

To add a user as a developer to all groups, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:user_to_groups[username@domain.tld]

# installation from source
bundle exec rake gitlab:import:user_to_groups[username@domain.tld] RAILS_ENV=production
```

## Add all users to all groups

To add all users to all groups, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:import:all_users_to_all_groups

# installation from source
bundle exec rake gitlab:import:all_users_to_all_groups RAILS_ENV=production
```

Administrators are added as owners so they can add additional users to the group.

## Update all users in a given group to `project_limit:0` and `can_create_group: false`

To update all users in given group to `project_limit: 0` and `can_create_group: false`, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:user_management:disable_project_and_group_creation\[:group_id\]

# installation from source
bundle exec rake gitlab:user_management:disable_project_and_group_creation\[:group_id\] RAILS_ENV=production
```

It updates all users in the given group, its subgroups and projects in this group namespace, with the noted limits.

## Control the number of billable users

Enable this setting to keep new users blocked until they have been cleared by the administrator.
Defaults to `false`:

```plaintext
block_auto_created_users: false
```

## Disable two-factor authentication for all users

This task disables two-factor authentication (2FA) for all users that have it enabled. This can be
useful if the GitLab `config/secrets.yml` file has been lost and users are unable
to log in, for example.

To disable two-factor authentication for all users, run:

```shell
# omnibus-gitlab
sudo gitlab-rake gitlab:two_factor:disable_for_all_users

# installation from source
bundle exec rake gitlab:two_factor:disable_for_all_users RAILS_ENV=production
```

## Rotate two-factor authentication encryption key

GitLab stores the secret data required for two-factor authentication (2FA) in an encrypted
database column. The encryption key for this data is known as `otp_key_base`, and is
stored in `config/secrets.yml`.

If that file is leaked, but the individual 2FA secrets have not, it's possible
to re-encrypt those secrets with a new encryption key. This allows you to change
the leaked key without forcing all users to change their 2FA details.

To rotate the two-factor authentication encryption key:

1. Look up the old key. This is in the `config/secrets.yml` file, but **make sure you're working
   with the production section**. The line you're interested in looks like this:

   ```yaml
   production:
     otp_key_base: fffffffffffffffffffffffffffffffffffffffffffffff
   ```

1. Generate a new secret:

   ```shell
   # omnibus-gitlab
   sudo gitlab-rake secret

   # installation from source
   bundle exec rake secret RAILS_ENV=production
   ```

1. Stop the GitLab server, back up the existing secrets file, and update the database:

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl stop
   sudo cp config/secrets.yml config/secrets.yml.bak
   sudo gitlab-rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key>

   # installation from source
   sudo /etc/init.d/gitlab stop
   cp config/secrets.yml config/secrets.yml.bak
   bundle exec rake gitlab:two_factor:rotate_key:apply filename=backup.csv old_key=<old key> new_key=<new key> RAILS_ENV=production
   ```

   The `<old key>` value can be read from `config/secrets.yml` (`<new key>` was
   generated earlier). The **encrypted** values for the user 2FA secrets are
   written to the specified `filename`. You can use this to rollback in case of
   error.

1. Change `config/secrets.yml` to set `otp_key_base` to `<new key>` and restart. Again, make sure
   you're operating in the **production** section.

   ```shell
   # omnibus-gitlab
   sudo gitlab-ctl start

   # installation from source
   sudo /etc/init.d/gitlab start
   ```

If there are any problems (perhaps using the wrong value for `old_key`), you can
restore your backup of `config/secrets.yml` and rollback the changes:

```shell
# omnibus-gitlab
sudo gitlab-ctl stop
sudo gitlab-rake gitlab:two_factor:rotate_key:rollback filename=backup.csv
sudo cp config/secrets.yml.bak config/secrets.yml
sudo gitlab-ctl start

# installation from source
sudo /etc/init.d/gitlab start
bundle exec rake gitlab:two_factor:rotate_key:rollback filename=backup.csv RAILS_ENV=production
cp config/secrets.yml.bak config/secrets.yml
sudo /etc/init.d/gitlab start

```
