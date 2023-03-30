---
stage: Manage
group: Authentication and Authorization
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: howto
---

# Moderate users (administration) **(FREE SELF)**

This is the administration documentation. For information about moderating users at the group level, see the [group-level documentation](../group/moderate_users.md).

GitLab administrators can moderate user access by approving, blocking, banning, or deactivating
users.

## Users pending approval

A user in _pending approval_ state requires action by an administrator. A user sign up can be in a
pending approval state because an administrator has enabled any of the following options:

- [Require administrator approval for new sign-ups](settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups) setting.
- [User cap](settings/sign_up_restrictions.md#user-cap).
- [Block auto-created users (OmniAuth)](../../integration/omniauth.md#configure-common-settings)
- [Block auto-created users (LDAP)](../../administration/auth/ldap/index.md#basic-configuration-settings)

When a user registers for an account while this setting is enabled:

- The user is placed in a **Pending approval** state.
- The user sees a message telling them their account is awaiting approval by an administrator.

A user pending approval:

- Is functionally identical to a [blocked](#block-a-user) user.
- Cannot sign in.
- Cannot access Git repositories or the GitLab API.
- Does not receive any notifications from GitLab.
- Does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

An administrator must [approve their sign up](#approve-or-reject-a-user-sign-up) to allow them to
sign in.

### View user sign ups pending approval

To view user sign ups pending approval:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Pending approval** tab.

### Approve or reject a user sign up

A user sign up pending approval can be approved or rejected from the Admin Area.

To approve or reject a user sign up:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Pending approval** tab.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Approve** or **Reject**.

Approving a user:

- Activates their account.
- Changes the user's state to active.
- Consumes a subscription [seat](../../subscriptions/self_managed/index.md#billable-users).

## Block and unblock users

GitLab administrators can block and unblock users.

### Block a user

To completely prevent access of a user to the GitLab instance,
administrators can choose to block the user.

Users can be blocked [via an abuse report](review_abuse_reports.md#blocking-users),
by removing them in LDAP, or directly from the Admin Area. To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Block**.

A blocked user:

- Cannot sign in.
- Cannot access Git repositories or the API.
- Does not receive any notifications from GitLab.
- Cannot use [slash commands](../../integration/slash_commands.md).
- Does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

Personal projects, and group and user history of the blocked user are left intact.

NOTE:
Users can also be blocked using the [GitLab API](../../api/users.md#block-user).

### Unblock a user

A blocked user can be unblocked from the Admin Area. To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Blocked** tab.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Unblock**.

The user's state is set to active and they consume a
[seat](../../subscriptions/self_managed/index.md#billable-users).

NOTE:
Users can also be unblocked using the [GitLab API](../../api/users.md#unblock-user).

The unblock option may be unavailable for LDAP users. To enable the unblock option,
the LDAP identity first needs to be deleted:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Blocked** tab.
1. Select a user.
1. Select the **Identities** tab.
1. Find the LDAP provider and select **Delete**.

## Activate and deactivate users

GitLab administrators can deactivate and activate users.

### Deactivate a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

To temporarily prevent access by a GitLab user that has no recent activity,
administrators can choose to deactivate the user.

Deactivating a user is functionally identical to [blocking a user](#block-and-unblock-users),
with the following differences:

- It does not prohibit the user from logging back in via the UI.
- Once a deactivated user logs back into the GitLab UI, their account is set to active.

A deactivated user:

- Cannot access Git repositories or the API.
- Does not receive any notifications from GitLab.
- Cannot use [slash commands](../../integration/slash_commands.md).
- Does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

Personal projects, and group and user history of the deactivated user are left intact.

NOTE:
Users are notified about account deactivation if
[user deactivation emails](settings/email.md#user-deactivation-emails) are enabled.

A user can be deactivated from the Admin Area. To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Deactivate**.

For the deactivation option to be visible to an administrator, the user:

- Must have a state of active.
- Must be [dormant](#automatically-deactivate-dormant-users).

NOTE:
Users can also be deactivated using the [GitLab API](../../api/users.md#deactivate-user).

### Automatically deactivate dormant users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/320875) in GitLab 14.0.
> - Customizable time period [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336747) in GitLab 15.4
> - The lower limit for inactive period set to 90 days [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100793) in GitLab 15.5

Administrators can enable automatic deactivation of users who either:

- Were created more than a week ago and have not signed in.
- Have no activity for a specified period of time (default and minimum is 90 days).

To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.
1. Under **Dormant users**, check **Deactivate dormant users after a period of inactivity**.
1. Under **Days of inactivity before deactivation**, enter the number of days before deactivation. Minimum value is 90 days.
1. Select **Save changes**.

When this feature is enabled, GitLab runs a job once a day to deactivate the dormant users.

A maximum of 100,000 users can be deactivated per day.

### Activate a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

A deactivated user can be activated from the Admin Area.

To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Deactivated** tab.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Activate**.

The user's state is set to active and they consume a
[seat](../../subscriptions/self_managed/index.md#billable-users).

NOTE:
A deactivated user can also activate their account themselves by logging back in via the UI.
Users can also be activated using the [GitLab API](../../api/users.md#activate-user).

## Ban and unban users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327353) in GitLab 14.2 [with a flag](../../administration/feature_flags.md) named `ban_user_feature_flag`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/330667) in GitLab 14.8.

FLAG:
On self-managed GitLab, by default this feature is available.
On GitLab.com, this feature is available to GitLab.com administrators only.

GitLab administrators can ban and unban users. Banned users are blocked, and their issues and merge requests are hidden.
The banned user's comments are still displayed. Hiding a banned user's comments is [tracked in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/327356).

### Ban a user

To block a user and hide their contributions, administrators can ban the user.

Users can be banned using the Admin Area. To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Ban user**.

The banned user does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

### Unban a user

A banned user can be unbanned using the Admin Area. To do this:

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Banned** tab.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Unban user**.

The user's state is set to active and they consume a
[seat](../../subscriptions/self_managed/index.md#billable-users).

### Delete a user

Use the Admin Area to delete users.

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Banned** tab.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Delete user**.
1. Type the username.
1. Select **Delete user**.

NOTE:
You can only delete a user if there are inherited or direct owners of a group. You cannot delete a user if they are the only group owner.

You can also delete a user and their contributions, such as merge requests, issues, and groups of which they are the only group owner.

1. On the top bar, select **Main menu > Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Banned** tab.
1. Optional. Select a user.
1. Select the **{settings}** **User administration** dropdown list.
1. Select **Delete user and contributions**.
1. Type the username.
1. Select **Delete user and contributions**.

NOTE:
Before 15.1, additionally groups of which deleted user were the only owner among direct members were deleted.

## Troubleshooting

When moderating users, you may need to perform bulk actions on them based on certain conditions. The following rails console scripts show some examples of this. You may [start a rails console session](../../administration/operations/rails_console.md#starting-a-rails-console-session) and use scripts similar to the following:

### Deactivate users that have no recent activity

Administrators can deactivate users that have no recent activity.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.deactivate!
end
```

### Block users that have no recent activity

Administrators can block users that have no recent activity.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
days_inactive = 90
inactive_users = User.active.where("last_activity_on <= ?", days_inactive.days.ago)

inactive_users.each do |user|
    puts "user '#{user.username}': #{user.last_activity_on}"
    user.block!
end
```

### Block or delete users that have no projects or groups

Administrators can block or delete users that have no projects or groups.

WARNING:
Commands that change data can cause damage if not run correctly or under the right conditions. Always run commands in a test environment first and have a backup instance ready to restore.

```ruby
users = User.where('id NOT IN (select distinct(user_id) from project_authorizations)')

# How many users are removed?
users.count

# If that count looks sane:

# You can either block the users:
users.each { |user|  user.blocked? ? nil  : user.block! }

# Or you can delete them:
  # need 'current user' (your user) for auditing purposes
current_user = User.find_by(username: '<your username>')

users.each do |user|
  DeleteUserWorker.perform_async(current_user.id, user.id)
end
```
