---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Modify global user settings **(FREE SELF)**

GitLab administrators can modify user settings for the entire GitLab instance.

## Prevent users from creating top-level groups

By default, new users can create top-level groups. To disable your users'
ability to create top-level groups:

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
