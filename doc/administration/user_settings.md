---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Modify global user settings

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

GitLab administrators can modify user settings for the entire GitLab instance.

## Use configuration files to prevent new users from creating top-level groups

By default, new users can create top-level groups. To disable new users'
ability to create top-level groups (does not affect existing users' setting), GitLab administrators can modify this setting:

- In GitLab 15.5 and later, using either:
  - The [GitLab UI](../administration/settings/account_and_limit_settings.md#prevent-new-users-from-creating-top-level-groups).
  - The [application setting API](../api/settings.md#change-application-settings).
- In GitLab 15.4 and earlier, in a configuration file by following the steps in this section.

To disable new users' ability to create top-level groups using the configuration file.

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_default_can_create_group'] = false
   ```

1. [Reconfigure and restart GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

For self-compiled installations:

1. Edit `config/gitlab.yml` and uncomment the following line:

   ```yaml
   # default_can_create_group: false  # default: true
   ```

1. [Restart GitLab](restart_gitlab.md#self-compiled-installations).

### Prevent existing users from creating top-level groups

Administrators can:

- Use the Admin area to [prevent an existing user from creating top-level groups](../administration/admin_area.md#prevent-a-user-from-creating-top-level-groups).
- Use the [modify an existing user API endpoint](../api/users.md#user-modification) to change the `can_create_group` setting.

## Prevent users from changing their usernames

By default, new users can change their usernames. To disable your users'
ability to change their usernames.

For Linux package installations:

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_username_changing_enabled'] = false
   ```

1. [Reconfigure and restart GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

For self-compiled installations:

1. Edit `config/gitlab.yml` and uncomment the following line:

   ```yaml
   # username_changing_enabled: false # default: true - User can change their username/namespace
   ```

1. [Restart GitLab](restart_gitlab.md#self-compiled-installations).

## Prevent Guest users from promoting to a higher role

On GitLab Ultimate, Guest users do not count toward paid seats. However, when a Guest user creates
projects and namespaces, they are automatically promoted to a higher role than Guest and occupy
a paid seat.

To prevent Guest users from being promoted to a higher role and occupying a paid seat,
set the user as [external](../administration/external_users.md).

External users cannot create personal projects or namespaces. If a user with the Guest role is promoted into a higher role by another user,
the external user setting must be removed before they can create personal projects or namespaces. For a complete list of restrictions for external
users, see [External users](../administration/external_users.md).
