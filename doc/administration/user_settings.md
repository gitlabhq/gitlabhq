---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Modify global user settings
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

You can modify settings for every user in your GitLab instance.

## Prerequisites

- You must be an administrator of GitLab Self-Managed.

## Prevent users from creating top-level groups

By default, new users can create top-level groups. How you prevent users from creating top-level groups differs between new and existing users.

### For new users

To prevent new users from creating top-level groups:

- In GitLab 15.5 and later, use either:
  - The [GitLab UI](settings/account_and_limit_settings.md#prevent-new-users-from-creating-top-level-groups).
  - The [Application settings API](../api/settings.md#update-application-settings).
- In GitLab 15.4 and earlier, modify a configuration file:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_default_can_create_group'] = false
   ```

1. [Reconfigure and restart GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

:::TabTitle Self-compiled (source)

1. Edit `config/gitlab.yml` and uncomment the following line:

   ```yaml
   # default_can_create_group: false  # default: true
   ```

1. [Restart GitLab](restart_gitlab.md#self-compiled-installations).

::EndTabs

### For existing users

To prevent existing users from creating top-level groups, use either:

- The [GitLab UI](admin_area.md#prevent-a-user-from-creating-top-level-groups).
- The [User API](../api/users.md#modify-a-user) to modify the `can_create_group` setting.

## Prevent users from changing their usernames

By default, users can change their usernames. To prevent users from changing their usernames:

::Tabs

:::TabTitle Linux package (Omnibus)

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_username_changing_enabled'] = false
   ```

1. [Reconfigure and restart GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

:::TabTitle Self-compiled (source)

1. Edit `config/gitlab.yml` and uncomment the following line:

   ```yaml
   # username_changing_enabled: false # default: true - User can change their username/namespace
   ```

1. [Restart GitLab](restart_gitlab.md#self-compiled-installations).

::EndTabs

## Prevent Guest users from promoting to a higher role

On GitLab Ultimate, Guest users do not count toward paid seats. However, when a Guest user creates
projects and namespaces, they are automatically promoted to a higher role than Guest and occupy
a paid seat.

To prevent Guest users from being promoted to a higher role and occupying a paid seat,
set the user as [external](external_users.md).

External users cannot create personal projects or namespaces. If a user with the Guest role is promoted into a higher role by another user,
the external user setting must be removed before they can create personal projects or namespaces. For a complete list of restrictions for external
users, see [External users](external_users.md).
