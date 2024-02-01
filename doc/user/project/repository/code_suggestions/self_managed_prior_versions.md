---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Enable Code Suggestions in GitLab 16.2 and earlier

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

WARNING:
On self-managed GitLab 16.0 and earlier, Code Suggestions are not available. To use this feature, you must have GitLab 16.1 or later. For optimal performance and full feature access, upgrade to GitLab 16.3 or later and [enable Code Suggestions then](self_managed.md).

To enable Code Suggestions on a self-managed instance for GitLab 16.1 or 16.2,
follow these instructions.

Prerequisites:

- You must be an administrator.
- You must have a [customer success manager](https://about.gitlab.com/handbook/customer-success/csm/]).
- You must have a [GitLab SaaS account](https://gitlab.com/users/sign_up). You do not need a Premium or Ultimate subscription.
- You must agree to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
- You must acknowledge that GitLab sends data from the instance, including personal data, to GitLab.com infrastructure.

NOTE:
If you do not have a customer success manager, you cannot participate in the free trial of Code Suggestions on self-managed GitLab. Upgrade to GitLab 16.3 or later to perform self-service onboarding.

## Enable for your SaaS account

Start by enabling Code Suggestions for your GitLab SaaS account:

1. Create a [personal access token](../../../profile/personal_access_tokens.md#create-a-personal-access-token)
   with the `api` scope.
1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Code Suggestions** section, select **Enable Code Suggestions**.
1. Select **Save changes**.

## Enable for the instance

Then enable Code Suggestions for your self-managed GitLab instance:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Code Suggestions** and:
   - Select **Turn on Code Suggestions for this instance**.
   - In **Personal access token**, enter your GitLab SaaS personal access token.
1. Select **Save changes**.

This setting is visible only in self-managed GitLab instances.

WARNING:
If you clear the **Turn on Code Suggestions for this instance** checkbox, the users in your instance can still use Code Suggestions for up to one hour, until the issued JSON web token (JWT) expires.

## Request access

Finally, contact your customer success manager to request access.
GitLab provisions access on a customer-by-customer basis for Code Suggestions
on self-managed instances.

Your customer success manager then provisions access by commenting on [issue 415393](https://gitlab.com/gitlab-org/gitlab/-/issues/415393) (internal access only).

After GitLab has provisioned access to Code Suggestions for your instance,
the users in your instance can now enable Code Suggestions.

## Upgrade to GitLab 16.3

If you have a GitLab Free subscription and upgrade to GitLab 16.3 or later,
to continue having early access to Code Suggestions, you must:

1. Have a Premium or Ultimate subscription. These subscriptions support cloud licensing.
1. Make sure you have the latest version of your [IDE extension](index.md#supported-editor-extensions).
1. [Manually synchronize your subscription](../../../../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details).
