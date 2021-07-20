---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Users pending approval

A user in _pending approval_ state requires action by an administrator. A user sign up can be in a
pending approval state because an administrator has enabled either, or both, of the following
options:

- [Require admin approval for new sign-ups](settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups) setting.
- [User cap](settings/sign_up_restrictions.md#user-cap).

When a user registers for an account while this setting is enabled:

- The user is placed in a **Pending approval** state.
- The user sees a message telling them their account is awaiting approval by an administrator.

A user pending approval:

- Is functionally identical to a [blocked](moderate_users.md#blocking-a-user) user.
- Cannot sign in.
- Cannot access Git repositories or the GitLab API.
- Does not receive any notifications from GitLab.
- Does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

An administrator must [approve their sign up](#approve-or-reject-a-user-sign-up) to allow them to
sign in.

## View user sign ups pending approval

To view user sign ups pending approval:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. On the left sidebar, select **Overview > Users**.
1. Select the **Pending approval** tab.

## Approve or reject a user sign up

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
