---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: User management Rake tasks
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab provides Rake tasks for managing users. Administrators can also use the **Admin** area to
[manage users](../admin_area.md#administering-users).

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

Administrators are added as maintainers and all other users are added as developers.

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
to sign in, for example.

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

1. Look up the old key in the `config/secrets.yml` file, but **make sure you're working
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

## Bulk assign users to GitLab Duo

You can assign users in bulk to GitLab Duo using a CSV file with the names of the users.
The CSV file must have a header named `username`, followed by the usernames on each subsequent row.

```plaintext
username
user1
user2
user3
user4
```

### GitLab Duo Pro

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142189) in GitLab 16.9.

{{< /history >}}

To perform bulk user assignment for GitLab Duo Pro, you can use the following Rake task:

```shell
bundle exec rake duo_pro:bulk_user_assignment DUO_PRO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

If you prefer to use square brackets in the file path, you can escape them or use double quotes:

```shell
bundle exec rake duo_pro:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "duo_pro:bulk_user_assignment[path/to/your/file.csv]"
```

### GitLab Duo Pro and Enterprise

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187230) in GitLab 18.0.

{{< /history >}}

#### GitLab Self-Managed

This Rake task bulk assigns GitLab Duo Pro or Enterprise seats at the instance level to a list of users from a
CSV file, based on the available purchased add-on.

To perform bulk user assignment for a GitLab Self-Managed instance:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv
```

If you prefer to use square brackets in the file path, you can escape them or use double quotes:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv]"
```

#### GitLab.com

GitLab.com administrators can also use this Rake task to bulk assign GitLab Duo Pro or Enterprise seats for GitLab.com
groups, based on the available purchased add-on for that group.

To perform bulk user assignment for a GitLab.com group:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment DUO_BULK_USER_FILE_PATH=path/to/your/file.csv NAMESPACE_ID=<namespace_id>
```

If you prefer to use square brackets in the file path, you can escape them or use double quotes:

```shell
bundle exec rake gitlab_subscriptions:duo:bulk_user_assignment\['path/to/your/file.csv','<namespace_id>'\]
# or
bundle exec rake "gitlab_subscriptions:duo:bulk_user_assignment[path/to/your/file.csv,<namespace_id>]"
```

## Troubleshooting

### Errors during bulk user assignment

When using the Rake task for bulk user assignment, you might encounter the following errors:

- `User is not found`: The specified user was not found. Please ensure the provided username matches an existing user.
- `ERROR_NO_SEATS_AVAILABLE`: No more seats are available for user assignment. Please see how to [view assigned GitLab Duo users](../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users) to check current seat assignments.
- `ERROR_INVALID_USER_MEMBERSHIP`: The user is not eligible for assignment due to being inactive, a bot, or a ghost. Please ensure the user is active and, if on GitLab.com, a member of the provided namespace.

## Related topics

- [Reset user passwords](../../security/reset_user_password.md#use-a-rake-task)
