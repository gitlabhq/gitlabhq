---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Deleting a user account
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Users can be deleted from a GitLab instance, either by:

- The user themselves.
- An administrator.

NOTE:
Deleting a user deletes all projects in that user namespace.

## Delete your own account

> - Delay between a user deleting their own account and deletion of the user record introduced in GitLab 16.0 [with a flag](../../../administration/feature_flags.md) named `delay_delete_own_user`. Enabled by default on GitLab.com.

FLAG:
On GitLab Self-Managed, by default this feature is not available. To make it available, an administrator can [enable the feature flag](../../../administration/feature_flags.md) named `delay_delete_own_user`. On GitLab.com, this feature is available. On GitLab Dedicated, this feature is not available.

On GitLab.com, it takes seven days from when you delete your own account to when your account is deleted. During this time:

- That user is [blocked](../../../administration/moderate_users.md#block-a-user).
- You cannot create a new account with the same username.

  NOTE:
  After the seven day time period is finished, any user can create a user account with that previously used username. Therefore, you should not assume that you will be able to create a new account with that username after the seven days, because it might be taken.

  You can [create a new account with the same email address](#create-a-new-account-with-the-same-email-address)
  if you remove that email address from your account first.

The following are deleted within an hour:

- Accounts with no issues, comments, notes, merge requests, or snippets.
- Accounts under paid namespaces.

As a user, to delete your own account:

1. On the left sidebar, select your avatar.
1. Select **Edit profile**.
1. On the left sidebar, select **Account**.
1. Select **Delete account**.

If you cannot delete your own account, submit a [personal data request](https://support.gitlab.io/account-deletion/)
to ask for your account and data to be removed from GitLab.

### Create a new account with the same email address

On GitLab.com, during the [time between you deleting your own account and your account getting deleted](#delete-your-own-account),
you cannot create a new account with the same email address or username.

To create a new account with the same email address, before you delete your account:

1. [Add a secondary email address](../_index.md#add-emails-to-your-user-profile)
   to your account.
1. [Change your primary email](../_index.md#change-your-primary-email) to this
   new secondary email address.
1. [Remove the now-secondary email address](../_index.md#delete-email-addresses-from-your-user-profile)
   from your account.
1. [Delete your own account](#delete-your-own-account).

You can now [create a new account](create_accounts.md) with the same email address as your original
primary email address.

## Delete users and user contributions

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed, GitLab Dedicated

As an administrator, to delete a user account:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Select a user.
1. Under the **Account** tab, select:
   - **Delete user** to delete only the user but maintain their [associated records](#associated-records). You can't use this option if
     the selected user is the sole owner of any groups.
   - **Delete user and contributions** to delete the user and their associated records. This option also removes all groups (and
     projects within these groups) where the user is the sole direct Owner of a group. Inherited ownership doesn't apply.

WARNING:
Using the **Delete user and contributions** option may result in removing more data than intended. See
[associated records](#associated-records) for additional details.

### Associated records

When deleting users, you can either:

- Delete just the user, but move contributions to a system-wide "Ghost User":
  - The `@ghost` acts as a container for all deleted users' contributions.
  - The user's profile and personal projects are deleted, instead of moved to the Ghost User.
- Delete the user and their contributions, including:
  - Abuse reports.
  - Emoji reactions.
  - Groups of which the user is the only user with the Owner role.
  - Personal access tokens.
  - Epics.
  - Issues.
  - Merge requests.
  - Snippets.
  - [Notes and comments](../../../api/notes.md)
    on other users' [commits](../../project/repository/_index.md#commit-changes-to-a-repository),
    [epics](../../group/epics/_index.md),
    [issues](../../project/issues/_index.md),
    [merge requests](../../project/merge_requests/_index.md)
    and [snippets](../../snippets.md).

In both cases, commits retain [user information](https://git-scm.com/book/en/v2/Git-Internals-Git-Objects#_git_commit_objects)
and therefore data integrity within a [Git repository](../../project/repository/_index.md).

An alternative to deleting is [blocking a user](../../../administration/moderate_users.md#block-a-user).

When a user is deleted from an [abuse report](../../../administration/review_abuse_reports.md) or spam log, these associated
records are always removed.

The deleting associated records option can be requested in the [API](../../../api/users.md#delete-a-user) as well as
the **Admin** area.

WARNING:
User approvals are associated with a user ID. Other user contributions do not have an associated user ID. When you delete a user and their contributions are moved to a "Ghost User", the approval contributions refer to a missing or invalid user ID. Instead of deleting users, consider [blocking](../../../administration/moderate_users.md#block-a-user), [banning](../../../administration/moderate_users.md#ban-a-user), or [deactivating](../../../administration/moderate_users.md#deactivate-a-user) them.

## Delete the root account on a self-managed instance

DETAILS:
**Offering:** GitLab Self-Managed

WARNING:
The root account is the most privileged account on the system. Deleting the root account might result in losing access to the instance [**Admin** area](../../../administration/admin_area.md) if there is no other administrator available on the instance.

You can delete the root account using either the UI or the [GitLab Rails console](../../../administration/operations/rails_console.md).

Before you delete the root account:

1. If you have created any [project](../../project/settings/project_access_tokens.md) or [personal access tokens](../../profile/personal_access_tokens.md) for the root account and use them in your workflow, transfer any necessary permissions or ownership from the root account to the new administrator.
1. [Back up your GitLab Self-Managed instance](../../../administration/backup_restore/backup_gitlab.md).
1. Consider [deactivating](../../../administration/moderate_users.md#deactivate-a-user) or [blocking](../../../administration/moderate_users.md#block-and-unblock-users) the root account instead.

### Use the UI

Prerequisites:

- You must be an administrator for the self-managed instance.

To delete the root account:

1. In the **Admin** area, [create a new user with administrator access](../../profile/account/create_accounts.md#create-users-in-admin-area). This ensures that you maintain administrator access to the instance whilst mitigating the risks associated with deleting the root account.
1. [Delete the root account](#delete-users-and-user-contributions).

### Use the GitLab Rails console

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

Prerequisites:

- You must have access to the GitLab Rails console.

To delete the root account, in the Rails console:

1. Give another existing user administrator access:

   ```ruby
   user = User.find(username: 'Username') # or use User.find_by(email: 'email@example.com') to find by email
   user.admin = true
   user.save!
   ```

   This ensures that you maintain administrator access to the instance whilst mitigating the risks associated with deleting the root account.

1. To delete the root account, do either of the following:

   - Block the root account:

     ```ruby
     # This needs to be a current admin user
     current_user = User.find(username: 'Username')

     # This is the root user we want to block
     user = User.find(username: 'Username')

     ::Users::BlockService.new(current_user).execute(user)
     ```

   - Deactivate the root user:

     ```ruby
     # This needs to be a current admin user
     current_user = User.find(username: 'Username')

     # This is the root user we want to deactivate
     user = User.find(username: 'Username')

     ::Users::DeactivateService.new(current_user, skip_authorization: true).execute(user)
     ```

## Troubleshooting

### Deleting a user results in a PostgreSQL null value error

There is [a known issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411) that results
in users not being deleted, and the following error generated:

```plaintext
ERROR: null value in column "user_id" violates not-null constraint
```

The error can be found in the [PostgreSQL log](../../../administration/logs/_index.md#postgresql-logs) and
in the **Retries** section of the [background jobs view](../../../administration/admin_area.md#background-jobs) in the **Admin** area.

If the user being deleted used the [iterations](../../group/iterations/_index.md) feature, such
as adding an issue to an iteration, you must use
[the workaround documented in the issue](https://gitlab.com/gitlab-org/gitlab/-/issues/349411#workaround)
to delete the user.
