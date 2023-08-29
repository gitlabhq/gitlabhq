---
stage: AI-powered
group: AI Model Validation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Code Suggestions on self-managed GitLab **(PREMIUM SELF BETA)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10653) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta) on self-managed GitLab.
> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - Code Suggestions in the GitLab WebIDE enabled for all GitLab-hosted customers.

Write code more efficiently by using generative AI to suggest code while you're developing.

Code Suggestions are available on GitLab Enterprise Edition.
Cloud licensing is required for Premium and Ultimate subscription tiers.

Code Suggestions are not available for GitLab Community Edition.

WARNING:
In GitLab 16.3 and later, only Premium and Ultimate customers can participate in the free trial of Code Suggestions on self-managed GitLab.

Usage of Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using Code Suggestions](index.md#code-suggestions-data-usage).

## Enable Code Suggestions on self-managed GitLab **(FREE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10653) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta).

When you enable Code Suggestions for your self-managed instance, you:

- Agree to the [GitLab testing agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
- Acknowledge that GitLab sends data from the instance, including personal data, to GitLab.com infrastructure.

How you enable Code Suggestions differs depending on your version of GitLab.

### GitLab 16.3 and later

Prerequisites:

- You are a new Code Suggestions customer as of GitLab 16.3.
- All of the users in your instance have the latest version of their IDE extension.
- You are an administrator.

To enable Code Suggestions for your self-managed GitLab instance:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Code Suggestions** and select **Turn on Code Suggestions for this instance**.
   You do not need to enter anything into the **Personal access token** field.
1. Select **Save changes**.

This setting is visible only in self-managed GitLab instances.

WARNING:
In GitLab 16.2 and earlier, if you clear the **Turn on code suggestions for this instance** checkbox, the users in your instance can still use Code Suggestions for up to one hour, until the issued JSON web token (JWT) expires.

To make sure Code Suggestions works immediately, you must [manually synchronize your subscription](#manually-synchronize-your-subscription).

The users in your instance can now use Code Suggestions.

### GitLab 16.2 and earlier

Prerequisites:

- You are an administrator.
- You have a [GitLab SaaS account](https://gitlab.com/users/sign_up). You do not need to have a GitLab SaaS subscription.

Then, you will:

1. Enable Code Suggestions for your SaaS account.
1. Enable Code Suggestions for the instance.
1. [Request early access](#request-access-to-code-suggestions) to the Code Suggestions Beta.

#### Enable Code Suggestions for your SaaS account

To enable Code Suggestions for your GitLab SaaS account:

1. Create a [personal access token](../../../profile/personal_access_tokens.md#create-a-personal-access-token)
   with the `api` scope.
1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Code Suggestions** section, select **Enable Code Suggestions**.
1. Select **Save changes**.

#### Enable Code Suggestions for the instance

To enable Code Suggestions for your self-managed GitLab instance:

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Code Suggestions** and:
   - Select **Turn on Code Suggestions for this instance**.
   - In **Personal access token**, enter your GitLab SaaS personal access token.
1. Select **Save changes**.

This setting is visible only in self-managed GitLab instances.

WARNING:
If you clear the **Turn on code suggestions for this instance** checkbox, the users in your instance can still use Code Suggestions for up to one hour, until the issued JSON web token (JWT) expires.

#### Request access to Code Suggestions

GitLab provisions access on a customer-by-customer basis for Code Suggestions
on self-managed instances. To request access:

1. Sign into your GitLab SaaS account.
1. Comment on [issue 415393](https://gitlab.com/gitlab-org/gitlab/-/issues/415393)
   and tag your customer success manager.

After GitLab has provisioned access to Code Suggestions for your instance,
the users in your instance can now enable Code Suggestions.

### Update GitLab

In GitLab 16.3 and later, GitLab is enforcing the cloud licensing requirement for Code Suggestions:

- The Premium and Ultimate subscription tiers support cloud Licensing.
- GitLab Free does not have cloud licensing support.

If you have a GitLab Free subscription and update to GitLab 16.3 or later,
to continue having early access to Code Suggestions, you must:

1. Have a [subscription that supports cloud licensing](https://about.gitlab.com/pricing/).
1. Make sure you have the latest version of your [IDE extension](index.md#supported-editor-extensions).
1. [Manually synchronize your subscription](#manually-synchronize-your-subscription).

#### Manually synchronize your subscription

You must [manually synchronize your subscription](../../../../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details) if either:

- You have already updated to GitLab 16.3 and have just bought a Premium or Ultimate tier subscription.
- You already have a Premium or Ultimate tier subscription and have just updated to GitLab 16.3.

Without the manual synchronization, it might take up to 24 hours to active Code Suggestions on your instance.

## Use Code Suggestions

Prerequisites:

- Code Suggestions must be enabled [for the instance](#enable-code-suggestions-on-self-managed-gitlab).
- You must have installed and configured a [supported IDE editor extension](index.md#supported-editor-extensions).

To use Code Suggestions:

1. Author your code. As you type, suggestions are displayed. Depending on the cursor position, the extension either:

   - Provides entire code snippets, like generating functions.
   - Completes the current line.

1. To accept a suggestion, press <kbd>Tab</kbd>.

Suggestions are best when writing new code. Editing existing functions or 'fill in the middle' of a function may not perform as expected.

GitLab is making improvements to the Code Suggestions to improve the quality. AI is non-deterministic, so you may not get the same suggestion every time with the same input.

This feature is currently in [Beta](../../../../policy/experiment-beta-support.md#beta).
Code Suggestions depends on both Google Vertex AI Codey APIs and the GitLab Code Suggestions service. We have built this feature to gracefully degrade and have controls in place to allow us to
mitigate abuse or misuse. GitLab may disable this feature for any or all customers at any time at our discretion.

### Data privacy

A self-managed GitLab instance does not generate the code suggestion. After successful
authentication to the self-managed instance, a token is generated.

The IDE/editor then uses this token to securely transmit data directly to
GitLab.com's Code Suggestions service for processing.

The Code Suggestion service then securely returns an AI-generated code suggestion.

Neither GitLab nor Google Vertex AI Codey APIs have any visibility into a self-managed customer's code other than
what is sent to generate the code suggestion.
