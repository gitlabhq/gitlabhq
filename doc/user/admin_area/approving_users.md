---
stage: Manage
group: Access
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: howto
---

# Users pending approval

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/4491) in GitLab 13.5.

When [Require admin approval for new sign-ups](settings/sign_up_restrictions.md#require-administrator-approval-for-new-sign-ups) is enabled, any user that signs up for an account using the registration form is placed under a **Pending approval** state.

A user pending approval is functionally identical to a [blocked](blocking_unblocking_users.md) user.

A user pending approval:

- Will not be able to sign in.
- Cannot access Git repositories or the API.
- Will not receive any notifications from GitLab.
- Does not consume a [seat](../../subscriptions/self_managed/index.md#billable-users).

## Approving a user

A user that is pending approval can be approved from the Admin Area. To do this:

1. Navigate to  **Admin Area > Overview > Users**.
1. Click on the **Pending approval** tab.
1. Select a user.
1. Under the **Account** tab, click **Approve user**.

Approving a user:

1. Activates their account.
1. Changes the user's state to active and it consumes a
[seat](../../subscriptions/self_managed/index.md#billable-users).
