---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Modify global user settings **(FREE SELF)**

GitLab administrators can modify user settings for the entire GitLab instance.

## Use configuration files to prevent new users from creating top-level groups

By default, new users can create top-level groups. To disable new users'
ability to create top-level groups (does not affect existing users' setting), GitLab administrators can modify this setting:

- In GitLab 15.5 and later, using either:
  - The [GitLab UI](../user/admin_area/settings/account_and_limit_settings.md#prevent-new-users-from-creating-top-level-groups).
  - The [application setting API](../api/settings.md#change-application-settings).
- In GitLab 15.4 and earlier, in a configuration file by following the steps in this section.

To disable new users' ability to create top-level groups using the configuration file:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_default_can_create_group'] = false
   ```

1. [Reconfigure and restart GitLab](restart_gitlab.md#omnibus-installations).

**Source installations**

1. Edit `config/gitlab.yml` and uncomment the following line:

   ```yaml
   # default_can_create_group: false  # default: true
   ```

1. [Restart GitLab](restart_gitlab.md#installations-from-source).

### Prevent existing users from creating top-level groups

Administrators can:

- Use the Admin Area to [prevent an existing user from creating top-level groups](../user/admin_area/index.md#prevent-a-user-from-creating-groups).
- Use the [modify an existing user API endpoint](../api/users.md#user-modification) to change the `can_create_group` setting.

## Prevent users from changing their usernames

By default, new users can change their usernames. To disable your users'
ability to change their usernames:

**Omnibus GitLab installations**

1. Edit `/etc/gitlab/gitlab.rb` and add the following line:

   ```ruby
   gitlab_rails['gitlab_username_changing_enabled'] = false
   ```

1. [Reconfigure and restart GitLab](restart_gitlab.md#omnibus-installations).

**Source installations**

1. Edit `config/gitlab.yml` and uncomment the following line:

   ```yaml
   # username_changing_enabled: false # default: true - User can change their username/namespace
   ```

1. [Restart GitLab](restart_gitlab.md#installations-from-source).
