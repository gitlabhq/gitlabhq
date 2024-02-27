---
stage: Govern
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Locked users

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

## Self-managed users

> - Configurable locked user policy [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27048) in GitLab 16.5.

By default, users are locked after 10 failed sign-in attempts. These users remain locked:

- For 10 minutes, after which time they are automatically unlocked.
- Until an administrator unlocks them from the [Admin Area](../administration/admin_area.md) or the command line in under 10 minutes.

In GitLab 16.5 and later, administrators can [use the API](../api/settings.md#list-of-settings-that-can-be-accessed-via-api-calls) to configure:

- The number of failed sign-in attempts that locks a user (`max_login_attempts`).
- The time period in minutes that the locked user is locked for, after the maximum number of failed sign-in attempts is reached (`failed_login_attempts_unlock_period_in_minutes`).

For example, an administrator can configure that five failed sign-in attempts locks a user, and that user will be locked for 60 minutes, with the following API call:

```shell
curl --request PUT --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/application/settings?max_login_attempts=5&failed_login_attempts_unlock_period_in_minutes=60"
```

## GitLab.com users

If 2FA is not enabled users are locked after three failed sign-in attempts within 24 hours. These users remain locked until:

- Their next successful sign-in, at which point they are sent an email with a six-digit unlock code and redirected to a verification page where they can unlock their account by entering the code.
- GitLab Support [manually unlock](https://handbook.gitlab.com/handbook/support/workflows/reinstating-blocked-accounts/#manual-unlock) the account after account ownership is verified.

If 2FA is enabled, users are locked after three failed sign-in attempts. Accounts are unlocked automatically after 30 minutes.

## Unlock a user from the Admin Area

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Overview > Users**.
1. Use the search bar to find the locked user.
1. From the **User administration** dropdown list, select **Unlock**.

## Unlock a user from the command line

To unlock a locked user:

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

The user should now be able to sign in.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
