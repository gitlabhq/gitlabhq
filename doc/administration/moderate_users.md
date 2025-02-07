---
stage: Fulfillment
group: Provision
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Moderate users
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

If you are an instance administrator, you have several options to moderate and control user access.

NOTE:
This topic is specifically related to user moderation in GitLab Self-Managed. For information related to groups, see the [group documentation](../user/group/moderate_users.md).

## Users pending approval

A user in _pending approval_ state requires action by an administrator. A user sign up can be in a
pending approval state because an administrator has enabled any of the following options:

- [Require administrator approval for new sign-ups](settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups) setting.
- [User cap](settings/sign_up_restrictions.md#user-cap).
- [Block auto-created users (OmniAuth)](../integration/omniauth.md#configure-common-settings)
- [Block auto-created users (LDAP)](auth/ldap/_index.md#basic-configuration-settings)

When a user registers for an account while this setting is enabled:

- The user is placed in a **Pending approval** state.
- The user sees a message telling them their account is awaiting approval by an administrator.

A user pending approval:

- Is functionally identical to a [blocked](#block-a-user) user.
- Cannot sign in.
- Cannot access Git repositories or the GitLab API.
- Does not receive any notifications from GitLab.
- Does not consume a [seat](../subscriptions/self_managed/_index.md#billable-users).

An administrator must [approve their sign up](#approve-or-reject-a-user-sign-up) to allow them to
sign in.

### View user sign ups pending approval

> - Filter users by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) in GitLab 17.0.

To view user sign ups pending approval:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box, filter by **State=Pending approval**, and press <kbd>Enter</kbd>.

### Approve or reject a user sign up

> - Filter users by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) in GitLab 17.0.

A user sign up pending approval can be approved or rejected from the **Admin** area.

To approve or reject a user sign up:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box, filter by **State=Pending approval** and press <kbd>Enter</kbd>.
1. For the user sign up you want to approve or reject, select the vertical ellipsis (**{ellipsis_v}**), then **Approve** or **Reject**.

Approving a user:

- Activates their account.
- Changes the user's state to active.
- Consumes a subscription [seat](../subscriptions/self_managed/_index.md#billable-users).

Rejecting a user:

- Prevents the user from signing in or accessing instance information.
- Deletes the user.

## View users pending role promotion

If [administrator approval for role promotions](settings/sign_up_restrictions.md#turn-on-administrator-approval-for-role-promotions) is turned on, membership requests that promote existing users into a billable role require administrator approval.

To view users pending role promotion:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Select **Role Promotions**.

A list of users with the highest role requested is displayed.
You can **Approve** or **Reject** the requests.

## Block and unblock users

GitLab administrators can block and unblock users.
You should block a user when you don't want them to access the instance, but you want to retain their data.

A blocked user:

- Cannot sign in or access any repositories.
  - Any associated data remains in these repositories.
- Cannot use [slash commands](../user/project/integrations/gitlab_slack_application.md#slash-commands).
- Does not occupy a [seat](../subscriptions/self_managed/_index.md#billable-users).

### Block a user

Prerequisites:

- You must be an administrator for the instance.

You can block a user's access to the instance.

To block a user:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. For the user you want to block, select the vertical ellipsis (**{ellipsis_v}**), then **Block**.

The user receives an email notification that their account has been blocked. After this email, they no longer receive notifications.

To report abuse from other users, see [report abuse](../user/report_abuse.md). For more information on abuse reports in the **Admin** area, see [resolving abuse reports](review_abuse_reports.md#resolving-abuse-reports).

### Unblock a user

> - Filter users by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) in GitLab 17.0.

A blocked user can be unblocked from the **Admin** area. To do this:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box, filter by **State=Blocked** and press <kbd>Enter</kbd>.
1. For the user you want to unblock, select the vertical ellipsis (**{ellipsis_v}**), then **Unblock**.

The user's state is set to active and they consume a
[seat](../subscriptions/self_managed/_index.md#billable-users).

NOTE:
Users can also be unblocked using the [GitLab API](../api/user_moderation.md#unblock-access-to-a-user).

The unblock option may be unavailable for LDAP users. To enable the unblock option,
the LDAP identity first needs to be deleted:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box, filter by **State=Blocked** and press <kbd>Enter</kbd>.
1. Select a user.
1. Select the **Identities** tab.
1. Find the LDAP provider and select **Delete**.

## Deactivate and reactivate users

GitLab administrators can deactivate and reactivate users.
You should deactivate a user if they have no recent activity, and you do not want them to occupy a seat on the instance.

A deactivated user:

- Can sign in to GitLab.
  - If a deactivated user signs in, they are automatically reactivated.
- Cannot access repositories or the API.
- Cannot use slash commands. For more information, see [slash commands](../user/project/integrations/gitlab_slack_application.md#slash-commands).
- Does not occupy a seat. For more information, see [billable users](../subscriptions/self_managed/_index.md#billable-users).

When you deactivate a user, their projects, groups, and history remain.

### Deactivate a user

Prerequisites:

- The user has had no activity in the last 90 days.

To deactivate a user:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. For the user you want to deactivate, select the vertical ellipsis (**{ellipsis_v}**) and then **Deactivate**.
1. On the dialog, select **Deactivate**.

The user receives an email notification that their account has been deactivated. After this email, they no longer receive notifications.
For more information, see [user deactivation emails](settings/email.md#user-deactivation-emails).

To deactivate users with the GitLab API, see [deactivate user](../api/user_moderation.md#deactivate-a-user). For information about permanent user restrictions, see [block and unblock users](#block-and-unblock-users).

To remove a user from a GitLab.com subscription, see
[Remove users from your subscription](../subscriptions/gitlab_com/_index.md#remove-users-from-subscription).

### Automatically deactivate dormant users

> - Customizable time period [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336747) in GitLab 15.4
> - The lower limit for inactive period set to 90 days [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/100793) in GitLab 15.5

Administrators can enable automatic deactivation of users who either:

- Were created more than a week ago and have not signed in.
- Have no activity for a specified period of time (default and minimum is 90 days).

To do this:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand the **Account and limit** section.
1. Under **Dormant users**, check **Deactivate dormant users after a period of inactivity**.
1. Under **Days of inactivity before deactivation**, enter the number of days before deactivation. Minimum value is 90 days.
1. Select **Save changes**.

When this feature is enabled, GitLab runs a daily job to deactivate the dormant users.

A maximum of 100,000 users can be deactivated per day.

NOTE:
GitLab generated bots are excluded from the automatic deactivation of dormant users.

### Automatically delete unconfirmed users

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab Self-Managed

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/352514) in GitLab 16.1 [with a flag](feature_flags.md) named `delete_unconfirmed_users_setting`. Disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124982) in GitLab 16.2.

Prerequisites:

- You must be an administrator.

You can enable automatic deletion of users who both:

- Never confirmed their email address.
- Signed up for GitLab more than a specified number of days in the past.

You can configure these settings using either the [Settings API](../api/settings.md) or in a Rails console:

```ruby
 Gitlab::CurrentSettings.update(delete_unconfirmed_users: true)
 Gitlab::CurrentSettings.update(unconfirmed_users_delete_after_days: 365)
```

When the `delete_unconfirmed_users` setting is enabled, GitLab runs a job once an hour to delete the unconfirmed users.
The job only deletes users who signed up more than `unconfirmed_users_delete_after_days` days in the past.

This job only runs when the `email_confirmation_setting` is set to `soft` or `hard`.

A maximum of 240,000 users can be deleted per day.

### Reactivate a user

> - Filter users by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) in GitLab 17.0.

You can reactivate a deactivated user from the **Admin** area.

To do this:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box, filter by **State=Deactivated** and press <kbd>Enter</kbd>.
1. For the user you want to reactivate, select the vertical ellipsis (**{ellipsis_v}**), then **Activate**.

The user's state is set to active and they consume a
[seat](../subscriptions/self_managed/_index.md#billable-users).

NOTE:
A deactivated user can also reactivate their account themselves by logging back in through the UI.
Users can also be reactivated using the [GitLab API](../api/user_moderation.md#reactivate-a-user).

## Ban and unban users

> - Hiding merge requests of banned users [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/107836) in GitLab 15.8 [with a flag](feature_flags.md) named `hide_merge_requests_from_banned_users`. Disabled by default.
> - Hiding comments of banned users [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112973) in GitLab 15.11 [with a flag](feature_flags.md) named `hidden_notes`. Disabled by default.
> - Hiding projects of banned users [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121488) in GitLab 16.2 [with a flag](feature_flags.md) named `hide_projects_of_banned_users`. Disabled by default.

GitLab administrators can ban and unban users.
You should ban a user when you want to block them and hide their activity from the instance.

A banned user:

- Cannot sign in or access any repositories.
  - Any associated projects, issues, merge requests, or comments are hidden.
- Cannot use [slash commands](../user/project/integrations/gitlab_slack_application.md#slash-commands).
- Does not occupy a [seat](../subscriptions/self_managed/_index.md#billable-users).

### Ban a user

To block a user and hide their contributions, administrators can ban the user.

To ban a user:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Next to the member you want to ban, select the vertical ellipsis (**{ellipsis_v}**).
1. From the dropdown list, select **Ban member**.

### Unban a user

> - Filter users by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) in GitLab 17.0.

To unban a user:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box , filter by **State=Banned** and press <kbd>Enter</kbd>.
1. Next to the member you want to ban, select the vertical ellipsis (**{ellipsis_v}**).
1. From the dropdown list, select **Unban member**.

The user's state is set to active and they consume a
[seat](../subscriptions/self_managed/_index.md#billable-users).

## Delete a user

Use the **Admin** area to delete users.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. For the user you want to delete, select the vertical ellipsis (**{ellipsis_v}**), then **Delete user**.
1. Type the username.
1. Select **Delete user**.

NOTE:
You can only delete a user if there are inherited or direct owners of a group. You cannot delete a user if they are the only group owner.

You can also delete a user and their contributions, such as merge requests, issues, and groups of which they are the only group owner.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. For the user you want to delete, select the vertical ellipsis (**{ellipsis_v}**), then **Delete user and contributions**.
1. Type the username.
1. Select **Delete user and contributions**.

NOTE:
Before 15.1, additionally groups of which deleted user were the only owner among direct members were deleted.

## Trust and untrust users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132402) in GitLab 16.5.
> - Filter users by state [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/238183) in GitLab 17.0.

You can trust and untrust users from the **Admin** area.

By default, a user is not trusted and is blocked from creating issues, notes, and snippets considered to be spam. When you trust a user, they can create issues, notes, and snippets without being blocked.

Prerequisites:

- You must be an administrator.

::Tabs

:::TabTitle Trust a user

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. Select a user.
1. From the **User administration** dropdown list, select **Trust user**.
1. On the confirmation dialog, select **Trust user**.

The user is trusted.

:::TabTitle Untrust a user

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Overview > Users**.
1. In the search box, filter by **State=Trusted** and press <kbd>Enter</kbd>.
1. Select a user.
1. From the **User administration** dropdown list, select **Untrust user**.
1. On the confirmation dialog, select **Untrust user**.

The user is untrusted.

::EndTabs

## Troubleshooting

When moderating users, you may need to perform bulk actions on them based on certain conditions. The following rails console scripts show some examples of this. You may [start a rails console session](operations/rails_console.md#starting-a-rails-console-session) and use scripts similar to the following:

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
