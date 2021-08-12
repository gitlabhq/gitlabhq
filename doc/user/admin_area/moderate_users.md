---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Moderate users

GitLab administrators can moderate user access by approving, blocking, banning, or deactivating
users.

## Users pending approval

A user in _pending approval_ state requires action by an administrator. A user sign up can be in a
pending approval state because an administrator has enabled either, or both, of the following
options:

- [Require admin approval for new sign-ups](settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups) setting.
- [User cap](settings/sign_up_restrictions.md#user-cap).

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

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Pending approval** tab.

### Approve or reject a user sign up

A user sign up pending approval can be approved or rejected from the Admin Area.

To approve or reject a user sign up:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Pending approval** tab.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Approve** or **Reject**.

Approving a user:

- Activates their account.
- Changes the user's state to active.
- Consumes a subscription [seat](../../subscriptions/self_managed/index.md#billable-users).

## Block and unblock users

GitLab administrators can block and unblock users.

### Block a user

In order to completely prevent access of a user to the GitLab instance,
administrators can choose to block the user.

Users can be blocked [via an abuse report](review_abuse_reports.md#blocking-users),
or directly from the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Block**.

A blocked user:

- Cannot log in.
- Cannot access Git repositories or the API.
- Does not receive any notifications from GitLab.
- Cannot use [slash commands](../../integration/slash_commands.md).
- Does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

Personal projects, and group and user history of the blocked user are left intact.

NOTE:
Users can also be blocked using the [GitLab API](../../api/users.md#block-user).

### Unblock a user

A blocked user can be unblocked from the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select on the **Blocked** tab.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Unblock**.

The user's state is set to active and they consume a
[seat](../../subscriptions/self_managed/index.md#billable-users).

NOTE:
Users can also be unblocked using the [GitLab API](../../api/users.md#unblock-user).

## Activate and deactivate users

GitLab administrators can deactivate and activate users.

### Deactivate a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

In order to temporarily prevent access by a GitLab user that has no recent activity,
administrators can choose to deactivate the user.

Deactivating a user is functionally identical to [blocking a user](#block-and-unblock-users),
with the following differences:

- It does not prohibit the user from logging back in via the UI.
- Once a deactivated user logs back into the GitLab UI, their account is set to active.

A deactivated user:

- Cannot access Git repositories or the API.
- Does not receive any notifications from GitLab.
- Does not be able to use [slash commands](../../integration/slash_commands.md).
- Does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

Personal projects, and group and user history of the deactivated user are left intact.

A user can be deactivated from the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Deactivate**.

For the deactivation option to be visible to an admin, the user:

- Must be currently active.
- Must not have signed in, or have any activity, in the last 90 days.

NOTE:
Users can also be deactivated using the [GitLab API](../../api/users.md#deactivate-user).

### Automatically deactivate dormant users

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/320875) in GitLab 14.0.

Administrators can enable automatic deactivation of users who have not signed in, or have no activity
in the last 90 days. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Settings > General**.
1. Expand the **Account and limit** section.
1. Under **Dormant users**, check **Deactivate dormant users after 90 days of inactivity**.
1. Select **Save changes**.

When this feature is enabled, GitLab runs a job once a day to deactivate the dormant users.

A maximum of 100,000 users can be deactivated per day.

### Activate a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

A deactivated user can be activated from the Admin Area.

To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Deactivated** tab.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Activate**.

The user's state is set to active and they consume a
[seat](../../subscriptions/self_managed/index.md#billable-users).

NOTE:
A deactivated user can also activate their account themselves by logging back in via the UI.
Users can also be activated using the [GitLab API](../../api/users.md#activate-user).

## Ban and unban users

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327353) in GitLab 14.2.

GitLab administrators can ban and unban users. Banned users are blocked, and their issues are hidden. 
The banned user's comments are still displayed. Hiding a banned user's comments is [tracked in this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/327356).

### Ban a user

To block a user and hide their contributions, administrators can ban the user.

Users can be banned using the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Ban user**.

The banned user does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

### Unban a user

A banned user can be unbanned using the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Banned** tab.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Unban user**.

The user's state is set to active and they consume a
[seat](../../subscriptions/self_managed/index.md#billable-users).
