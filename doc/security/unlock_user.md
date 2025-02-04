---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Locked user accounts
---

GitLab locks a user account after the user unsuccessfully attempts to sign in several times.

## GitLab.com users

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com

If two-factor authentication (2FA) is enabled, accounts are locked after three failed sign-in attempts. Accounts are unlocked automatically after 30 minutes.

If 2FA is not enabled user accounts are locked after three failed sign-in attempts within 24 hours. Accounts remain locked until:

- The next successful sign-in, at which point the user must verify their identity with a code sent to their email.
- GitLab Support verifies the identity of the user and [manually unlocks](https://handbook.gitlab.com/handbook/support/workflows/reinstating-blocked-accounts/#manual-unlock) the account.

## GitLab Self-Managed and GitLab Dedicated users

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

> - Configurable locked user policy [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27048) in GitLab 16.5.

By default, user accounts are locked after 10 failed sign-in attempts. Accounts are unlocked automatically after 10 minutes.

In GitLab 16.5 and later, administrators can use the [Application settings API](../api/settings.md#update-application-settings) to modify the `max_login_attempts` or `failed_login_attempts_unlock_period_in_minutes` settings.

Administrators can unlock accounts immediately by using the following tasks:

### Unlock user accounts from the Admin area

Prerequisites

- You must be an administrator of GitLab Self-Managed.

To unlock an account from the Admin area:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Use the search bar to find the locked user.
1. From the **User administration** dropdown list, select **Unlock**.

The user can now sign in.

### Unlock user accounts from the command line

Prerequisites

- You must be an administrator of GitLab Self-Managed.

To unlock an account from the command line:

1. SSH into your GitLab server.
1. Start a Ruby on Rails console:

   ```shell
   ## For Omnibus GitLab
   sudo gitlab-rails console -e production

   ## For installations from source
   sudo -u git -H bundle exec rails console -e production
   ```

1. Find the user to unlock. You can search by email:

   ```ruby
   user = User.find_by(email: 'admin@local.host')
   ```

   Or you can search by ID:

   ```ruby
   user = User.where(id: 1).first
   ```

1. Unlock the user:

   ```ruby
   user.unlock_access!
   ```

1. Exit the console with <kbd>Control</kbd>+<kbd>d</kbd>.

The user can now sign in.
