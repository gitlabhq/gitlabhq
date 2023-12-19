---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions on self-managed GitLab **(SELF BETA)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10653) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta) on self-managed GitLab.
> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - Code Suggestions in the GitLab WebIDE enabled for all GitLab-hosted customers.

Write code more efficiently by using generative AI to suggest code while you're developing.

GitLab Duo Code Suggestions are available on GitLab Enterprise Edition.

Code Suggestions are not available for GitLab Community Edition.

> In GitLab 16.3 and later, to participate in the free trial of Code Suggestions on self-managed GitLab, you must:
>
> - Be a Premium or Ultimate customer.
> - Have activated cloud licensing.

Usage of Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using Code Suggestions](index.md#code-suggestions-data-usage).

## Enable Code Suggestions on self-managed GitLab

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10653) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta).
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139916) in GitLab 16.8. Available to a percentage of users.

When you enable Code Suggestions for your self-managed instance, you:

- Agree to the [GitLab testing agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
- Acknowledge that GitLab sends data from the instance, including personal data, to GitLab.com infrastructure.

How you enable Code Suggestions for your instance differs depending on your version of GitLab.

### GitLab 16.3 and later **(PREMIUM)**

Prerequisites:

- You are a new Code Suggestions customer as of GitLab 16.3.
- All of the users in your instance have the latest version of their IDE extension.
- You are an administrator.

To enable Code Suggestions for your self-managed GitLab instance:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Code Suggestions** and select **Turn on Code Suggestions for this instance**.
   In GitLab 16.3, you do not need to enter anything into the **Personal access token** field.
   In GitLab 16.4 and later, there is no **Personal access token** field.
1. Select **Save changes**.

This setting is visible only in self-managed GitLab instances.

WARNING:
In GitLab 16.2 and earlier, if you clear the **Turn on Code Suggestions for this instance** checkbox, the users in your instance can still use Code Suggestions for up to one hour, until the issued JSON web token (JWT) expires.

To make sure Code Suggestions works immediately, you must [manually synchronize your subscription](#manually-synchronize-your-subscription).

The users in your instance can now use Code Suggestions.

### GitLab 16.2 and earlier

FLAG:
On self-managed GitLab 16.0 and earlier, GitLab Duo Code Suggestions is not available. To use this feature, you must have GitLab 16.1 or later. For optimal performance and full feature access, you should upgrade to GitLab 16.3 or later, which supports cloud licensing.

Prerequisites:

- You are an administrator.
- You have a [customer success manager](https://about.gitlab.com/handbook/customer-success/csm/]).
- You have a [GitLab SaaS account](https://gitlab.com/users/sign_up). You do not need to have a GitLab SaaS subscription.

NOTE:
If you do not have a customer success manager, you cannot participate in the free trial of Code Suggestions on self-managed GitLab. Upgrade to GitLab 16.3 to [perform self-service onboarding](#gitlab-163-and-later).

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

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Code Suggestions** and:
   - Select **Turn on Code Suggestions for this instance**.
   - In **Personal access token**, enter your GitLab SaaS personal access token.
1. Select **Save changes**.

This setting is visible only in self-managed GitLab instances.

WARNING:
If you clear the **Turn on Code Suggestions for this instance** checkbox, the users in your instance can still use Code Suggestions for up to one hour, until the issued JSON web token (JWT) expires.

#### Request access to Code Suggestions

GitLab provisions access on a customer-by-customer basis for Code Suggestions
on self-managed instances. To request access, contact your customer success manager.

Your customer success manager then provisions access by commenting on [issue 415393](https://gitlab.com/gitlab-org/gitlab/-/issues/415393) (internal access only).

After GitLab has provisioned access to Code Suggestions for your instance,
the users in your instance can now enable Code Suggestions.

### Configure network and proxy settings

Configure any firewalls to allow outbound connections to `https://codesuggestions.gitlab.com/`.

If your GitLab instance uses an HTTP proxy server to access the internet, ensure
the server is configured to allow outbound connections, including the
[`gitlab_workhorse` environment variable](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

### Upgrade GitLab

In GitLab 16.3 and later, GitLab is enforcing the cloud licensing requirement for Code Suggestions:

- The Premium and Ultimate subscription tiers support cloud licensing.
- GitLab Free does not have cloud licensing support.

If you have a GitLab Free subscription and upgrade to GitLab 16.3 or later,
to continue having early access to Code Suggestions, you must:

1. Have a [subscription that supports cloud licensing](https://about.gitlab.com/pricing/).
1. Make sure you have the latest version of your [IDE extension](index.md#supported-editor-extensions).
1. [Manually synchronize your subscription](#manually-synchronize-your-subscription).

#### Manually synchronize your subscription

You must [manually synchronize your subscription](../../../../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details) if either:

- You have already upgraded to GitLab 16.3 and have just bought a Premium or Ultimate tier subscription.
- You already have a Premium or Ultimate tier subscription and have just upgraded to GitLab 16.3.

Without the manual synchronization, it might take up to 24 hours to active Code Suggestions on your instance.

## Use Code Suggestions

Prerequisites:

- You must have a [supported IDE editor extension](index.md#supported-editor-extensions).
- Code Suggestions must be enabled [for your instance](self_managed.md#enable-code-suggestions-on-self-managed-gitlab).

To use Code Suggestions:

1. Author your code. As you type, suggestions are displayed.
   Code Suggestions provide code snippets or complete the current line, depending on the cursor position.
1. Describe the requirements in natural language. Be concise and specific. Code Suggestions generates functions and code snippets as appropriate.
1. To accept a suggestion, press <kbd>Tab</kbd>.
1. To ignore a suggestion, keep typing as you usually would.
1. To explicitly reject a suggestion, press <kbd>Esc</kbd>.

Things to remember:

- AI is non-deterministic, so you may not get the same suggestion every time with the same input.
- Just like product requirements, writing clear, descriptive, and specific tasks results in quality generated code.

### Data privacy

A self-managed GitLab instance does not generate the code suggestion. After successful
authentication to the self-managed instance, a token is generated.

The IDE/editor then uses this token to securely transmit data directly to
GitLab.com's Code Suggestions service via the [Cloud Connector gateway service](../../../../architecture/blueprints/cloud_connector/index.md) for processing.

The Code Suggestions service then securely returns an AI-generated code suggestion.

Neither GitLab nor Google Vertex AI Codey APIs have any visibility into a self-managed customer's code other than
what is sent to generate the code suggestion.

## Disable Code Suggestions

Individual users can disable Code Suggestions by disabling the feature in their
[installed IDE editor extension](index.md#supported-editor-extensions).
