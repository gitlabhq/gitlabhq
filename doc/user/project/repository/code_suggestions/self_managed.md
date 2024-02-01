---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions on self-managed GitLab

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** Self-managed

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10653) in GitLab 16.1 as [Beta](../../../../policy/experiment-beta-support.md#beta) on self-managed GitLab.
> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - Code Suggestions in the GitLab Web IDE enabled for all GitLab-hosted customers.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.7.
> - [Enabled self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139916) in GitLab 16.8.

Get started using Code Suggestions in your IDE. These instructions apply to users
of GitLab self-managed instances.

Prerequisites:

- You must be using [one of the supported IDE extensions](index.md#supported-editor-extensions).
- Code Suggestions must be [enabled for the instance](#enable-code-suggestions).

To use Code Suggestions:

1. Author your code.
   As you type, suggestions are displayed. Code Suggestions provide code snippets
   or completes the current line, depending on the cursor position.

1. Describe the requirements in natural language.
   Code Suggestions generates functions and code snippets based on the context provided.

1. To accept a suggestion, press <kbd>Tab</kbd>. To reject a suggestion, press <kbd>Esc</kbd>.
1. To ignore a suggestion, keep typing as you usually would.

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

## Enable Code Suggestions

How you enable Code Suggestions for your instance depends on your GitLab version.

The following instructions apply to GitLab 16.3 and later.
To use Code Suggestions on a self-managed instance in 16.1 or 16.2,
follow [these instructions](self_managed_prior_versions.md).

Prerequisites:

- You must be a new Code Suggestions customer. If you've used Code Suggestions in the past,
  see the [upgrade steps](self_managed_prior_versions.md#upgrade-to-gitlab-163).
- You must have a Premium or Ultimate subscription. These tiers support cloud licensing, which is required.
- All of the users in your instance must have the latest version of their
  [IDE extension](index.md#supported-editor-extensions).
- You must be an administrator.
- You must agree to the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
- You must acknowledge that GitLab sends data from the instance, including personal data, to GitLab.com infrastructure.

[What's my GitLab version](../../../version.md)?

### Configure network and proxy settings

The first step is to configure any firewalls to allow outbound connections to `https://cloud.gitlab.com/`.

If your GitLab instance uses an HTTP proxy server to access the internet, ensure
the server is configured to allow outbound connections, including the
[`gitlab_workhorse` environment variable](https://docs.gitlab.com/omnibus/settings/environment-variables.html).

### Enable Code Suggestions for the instance

The second step is to enable Code Suggestions for your self-managed instance:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **AI-powered features** and select **Enable Code Suggestions for this instance**.

   In GitLab 16.3, leave the **Personal access token** text box blank.
   In GitLab 16.4 and later, the **Personal access token** text box does not exist.

1. Select **Save changes**.
1. [Manually synchronize your subscription](../../../../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details).

The users in your instance can now use Code Suggestions.

## Manually synchronize your subscription

You must [manually synchronize your subscription](../../../../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details) if either:

- You have already upgraded to GitLab 16.3 and have just bought a Premium or Ultimate subscription.
- You already have a Premium or Ultimate subscription and have just upgraded to GitLab 16.3.

Without the manual synchronization, it might take up to 24 hours to active Code Suggestions on your instance.

## Data privacy

A self-managed GitLab instance does not generate Code Suggestions. After successful
authentication to the self-managed instance, a token is generated.

The IDE/editor then uses this token to securely transmit data directly to the
GitLab.com Code Suggestions service through the [Cloud Connector gateway service](../../../../architecture/blueprints/cloud_connector/index.md) for processing.

The Code Suggestions service then securely returns the AI-generated suggestion.

Neither GitLab nor Google Vertex AI Codey APIs have any visibility into self-managed customers' code,
other than what is sent to generate the suggestion.

## Disable Code Suggestions

To disable Code Suggestions, disable the feature in your IDE editor extension.
