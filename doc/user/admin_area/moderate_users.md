---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Moderate users

GitLab administrators can moderate user access by blocking, banning, or deactivating users.

## Blocking and unblocking users

GitLab administrators can block and unblock users.

### Blocking a user

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

Personal projects, and group and user history of the blocked user are left intact.

Users can also be blocked using the [GitLab API](../../api/users.md#block-user).

NOTE:
A blocked user does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

### Unblocking a user

A blocked user can be unblocked from the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select on the **Blocked** tab.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Unblock**.

Users can also be unblocked using the [GitLab API](../../api/users.md#unblock-user).

NOTE:
Unblocking a user changes the user's state to active and consumes a
[seat](../../subscriptions/self_managed/index.md#billable-users).

## Activating and deactivating users

GitLab administrators can deactivate and activate users.

### Deactivating a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

In order to temporarily prevent access by a GitLab user that has no recent activity,
administrators can choose to deactivate the user.

Deactivating a user is functionally identical to [blocking a user](#blocking-and-unblocking-users),
with the following differences:

- It does not prohibit the user from logging back in via the UI.
- Once a deactivated user logs back into the GitLab UI, their account is set to active.

A deactivated user:

- Cannot access Git repositories or the API.
- Does not receive any notifications from GitLab.
- Does not be able to use [slash commands](../../integration/slash_commands.md).

Personal projects, and group and user history of the deactivated user are left intact.

A user can be deactivated from the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Deactivate**.

Please note that for the deactivation option to be visible to an admin, the user:

- Must be currently active.
- Must not have signed in, or have any activity, in the last 90 days.

Users can also be deactivated using the [GitLab API](../../api/users.md#deactivate-user).

NOTE:
A deactivated user does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

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

### Activating a user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22257) in GitLab 12.4.

A deactivated user can be activated from the Admin Area.

To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Deactivated** tab.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Activate**.

Users can also be activated using the [GitLab API](../../api/users.md#activate-user).

NOTE:
Activating a user changes the user's state to active and consumes a
[seat](../../subscriptions/self_managed/index.md#billable-users).

NOTE:
A deactivated user can also activate their account themselves by logging back in via the UI.

## Ban and unban users

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/327353) in GitLab 13.12.

GitLab administrators can ban users.

NOTE:
This feature is behind a feature flag that is disabled by default. GitLab administrators
with access to the GitLab Rails console can [enable](../../administration/feature_flags.md)
this feature for your GitLab instance.

### Ban a user

To completely block a user, administrators can choose to ban the user.

Users can be banned using the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Ban user**.

NOTE:
This feature is a work in progress. Currently, banning a user
only blocks them and does not hide their comments or issues.
This functionality is planned to be implemented in follow up issues.

### Unban a user

A banned user can be unbanned using the Admin Area. To do this:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Banned** tab.
1. (Optional) Select a user.
1. Select the **{settings}** **User administration** dropdown.
1. Select **Unban user**.

NOTE:
Unbanning a user changes the user's state to active and consumes a
[seat](../../subscriptions/self_managed/index.md#billable-users).
