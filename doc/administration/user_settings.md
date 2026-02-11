---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Modify global user settings
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

You can modify settings for every user in your GitLab instance.

Prerequisites:

- You must be an administrator for the instance.

## Prevent users from creating top-level groups

You can prevent users from creating top-level groups.

When group creation is prevented:

- Users cannot create top-level groups.
- Users can create subgroups in groups where they have the Maintainer or Owner role, depending on the
  [subgroup creation permissions](../user/group/subgroups/_index.md#change-who-can-create-subgroups)
  for the group.

To prevent users from creating top-level groups, use one of these methods:

| Method        | For new users                                                                                                         | For existing users |
| ------------- | --------------------------------------------------------------------------------------------------------------------- | ------------------ |
| UI            | [Account and limit settings](settings/account_and_limit_settings.md#prevent-new-users-from-creating-top-level-groups) | [User settings in the Admin area](admin_area.md#prevent-a-user-from-creating-top-level-groups) |
| API           | [Application settings API](../api/settings.md#update-application-settings) to modify the `can_create_group` setting   | [Users API](../api/users.md#modify-a-user) to modify the `can_create_group` setting |
| Rails console | None                                                                                                                  | [Use the Rails console](#use-the-rails-console) |

### Use the Rails console

You can use the Rails console to prevent existing users from creating top-level groups.
Use this method when making bulk updates to multiple users.

To prevent existing users from creating top-level groups:

1. Start a [Rails console session](operations/rails_console.md#starting-a-rails-console-session).
1. Run one of these commands:

   - To prevent group creation for all existing users except administrators:

     ```ruby
     User.where.not(admin: true).update_all(can_create_group: false)
     ```

   - To prevent group creation for a specific user:

     ```ruby
     User.find_by(username: 'someuser').update(can_create_group: false)
     ```

1. Exit the console:

   ```ruby
   exit
   ```

## Prevent users from changing their usernames

By default, users can change their usernames. To prevent users from changing their usernames:

{{< tabs >}}

{{< tab title="Linux package (Omnibus)" >}}

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_username_changing_enabled'] = false
   ```

1. [Reconfigure and restart GitLab](restart_gitlab.md#reconfigure-a-linux-package-installation).

{{< /tab >}}

{{< tab title="Self-compiled (source)" >}}

1. Edit `config/gitlab.yml` and uncomment the following line:

   ```yaml
   # username_changing_enabled: false # default: true - User can change their username/namespace
   ```

1. [Restart GitLab](restart_gitlab.md#self-compiled-installations).

{{< /tab >}}

{{< /tabs >}}

## Prevent Guest users from promoting to a higher role

On GitLab Ultimate, Guest users do not count toward paid seats. However, when a Guest user creates
projects and namespaces, they are automatically promoted to a higher role than Guest and occupy
a paid seat.

To prevent Guest users from being promoted to a higher role and occupying a paid seat,
set the user as [external](external_users.md).

External users cannot create personal projects or namespaces. If a user with the Guest role is promoted into a higher role by another user,
the external user setting must be removed before they can create personal projects or namespaces. For a complete list of restrictions for external
users, see [External users](external_users.md).
