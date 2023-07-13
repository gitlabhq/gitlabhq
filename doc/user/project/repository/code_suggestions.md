---
stage: ModelOps
group: AI Assisted
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Code Suggestions (Beta) **(FREE)**

> - [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Beta](../../../policy/experiment-beta-support.md#beta) for early access Ultimate customers on GitLab.com.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/408104) as opt-in with GitLab 15.11 as [Beta](../../../policy/experiment-beta-support.md#beta).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1.
> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10653) in GitLab 16.1 as [Beta](../../../policy/experiment-beta-support.md#beta) on self-managed GitLab.
> - Code suggestions in the GitLab WebIDE enabled for all GitLab-hosted customers.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.

WARNING:
This feature is in [Beta](../../../policy/experiment-beta-support.md#beta).
Beta users should read about the [known limitations](#known-limitations). We look forward to hearing your [feedback](#feedback).

Write code more efficiently by using generative AI to suggest code while you're developing.

Code Suggestions are available:

- To users of GitLab SaaS (by default) and self-managed GitLab Enterprise Edition (when requested). Code Suggestions are not available for GitLab Community Edition.
- In VS Code and Microsoft Visual Studio when you have the corresponding GitLab extension installed.
- In the GitLab WebIDE

<div class="video-fallback">
  <a href="https://www.youtube.com/watch?v=WnxBYxN2-p4">View an end-to-end demo of Code Suggestions in VS Code</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/WnxBYxN2-p4" frameborder="0" allowfullscreen> </iframe>
</figure>

Usage of Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using Code Suggestions](#code-suggestions-data-usage).

## Supported languages

The best results from Code Suggestions are expected [for languages the Google Vertex AI Codey APIs](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview#supported_coding_languages) directly support:

- C++
- C#
- Go
- Google SQL
- Java
- JavaScript
- Kotlin
- PHP
- Python
- Ruby
- Rust
- Scala
- Swift
- TypeScript

 Supported [code infrastructure interfaces](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview#supported_code_infrastructure_interfaces) include:

- Google Cloud CLI
- Kubernetes Resource Model (KRM)
- Terraform

Suggestion quality for other languages and using natural language code comments to request completions may not yet result in high-quality suggestions.

## Enable Code Suggestions on GitLab SaaS **(FREE SAAS)**

Code Suggestions can be enabled [for all members of a group](../../group/manage.md#enable-code-suggestions).

Each individual user must also choose to enable Code Suggestions.

### Enable Code Suggestions for an individual user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1 as [Beta](../../../policy/experiment-beta-support.md#beta).

Each user can enable Code Suggestions for themselves:

1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Code Suggestions** section, select the **Enable Code Suggestions** checkbox.
1. Select **Save changes**.

If Code Suggestions is enabled for the group, the group setting overrides the user setting.

NOTE:
This setting controls Code Suggestions for all IDEs. Support for [more granular control per IDE](https://gitlab.com/groups/gitlab-org/-/epics/10624) is proposed.

## Enable Code Suggestions on self-managed GitLab **(FREE SELF)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10653) in GitLab 16.1 as [Beta](../../../policy/experiment-beta-support.md#beta).

To enable Code Suggestions on a self-managed GitLab EE instance, you must:

- Be an administrator.
- Have a [GitLab SaaS account](https://gitlab.com/users/sign_up).
You do not need to have a GitLab SaaS subscription.

Then, you will:

1. Enable Code Suggestions for your SaaS account.
1. Enable Code Suggestions for the instance.
1. [Request early access](#request-access-to-code-suggestions) to the Code Suggestions Beta.

### Enable Code Suggestions for your SaaS account

To enable Code Suggestions for your GitLab SaaS account:

1. Create a [personal access token](../../profile/personal_access_tokens.md#create-a-personal-access-token)
   with the `api` scope.
1. On the left sidebar, select your avatar.
1. Select **Preferences**.
1. In the **Code Suggestions** section, select **Enable Code Suggestions**.
1. Select **Save changes**.

### Enable Code Suggestions for the instance

You must enable Code Suggestions for the instance. When you do this, you:

- Agree to the [GitLab testing agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
- Acknowledge that GitLab:
  - Sends data from the instance, including personal data, to GitLab.com infrastructure.

To enable Code Suggestions for your self-managed GitLab instance:

1. On the left sidebar, expand the top-most chevron (**{chevron-down}**).
1. Select **Admin Area**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Code Suggestions** and:
   - Select **Turn on Code Suggestions for this instance**.
   - In **Personal access token**, enter your GitLab SaaS personal access token.
1. Select **Save changes**.

This setting is visible only in self-managed GitLab instances.

WARNING:
If you clear the **Turn on code suggestions for this instance** checkbox, the users in your instance can still use Code Suggestions for up to one hour, until the issued JSON web token (JWT) expires.

### Request access to Code Suggestions

GitLab provisions access on a customer-by-customer basis for Code Suggestions
on self-managed instances. To request access:

1. Sign into your GitLab SaaS account.
1. Comment on [issue 415393](https://gitlab.com/gitlab-org/gitlab/-/issues/415393)
   and tag your customer success manager.

After GitLab has provisioned access to Code Suggestions for your instance,
the users in your instance can now enable Code Suggestions.

## Enable Code Suggestions in other IDEs and editors

We have experimental support for Code Suggestions in JetBrains, Neovim, Emacs, Sublime, etc.

More details in this [blog](https://about.gitlab.com/blog/2023/06/01/extending-code-suggestions/).

## Use Code Suggestions

Prerequisites:

- For self-managed GitLab, Code Suggestions must be enabled [for the instance](#enable-code-suggestions-on-self-managed-gitlab).
- For GitLab SaaS, Code Suggestions must be enabled [for the top-level group](../../group/manage.md#enable-code-suggestions) and [for your user account](#enable-code-suggestions-for-an-individual-user).
- To use VS Code, ensure you have installed [the VS Code GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
- To use Microsoft Visual Studio, ensure you have installed [the Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio).

To use Code Suggestions:

1. Author your code. As you type, suggestions are displayed. Depending on the cursor position, the extension either:

   - Provides entire code snippets, like generating functions.
   - Completes the current line.

1. To accept a suggestion, press <kbd>Tab</kbd>.

Suggestions are best when writing new code. Editing existing functions or 'fill in the middle' of a function may not perform as expected.

GitLab is making improvements to the Code Suggestions to improve the quality. AI is non-deterministic, so you may not get the same suggestion every time with the same input.

This feature is currently in [Beta](../../../policy/experiment-beta-support.md#beta).
Code Suggestions depends on both Google Vertex AI Codey APIs and the GitLab Code Suggestions service. We have built this feature to gracefully degrade and have controls in place to allow us to
mitigate abuse or misuse. GitLab may disable this feature for any or all customers at any time at our discretion.

## Code Suggestions data usage

Code Suggestions is a generative artificial intelligence (AI) model.

Your personal access token enables a secure API connection to GitLab.com.
This API connection securely transmits a context window from your IDE/editor to the Code Suggestions GitLab hosted service which calls Google Vertex AI Codey APIs,
and the generated suggestion is transmitted back to your IDE/editor.

GitLab currently leverages [Google Cloud's Vertex AI Codey API models](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview).

### Data privacy

No new additional data is collected to enable this feature. Private non-public GitLab customer data is
not used as training data.

Learn more about Google Vertex AI Codey APIs [Data Governance](https://cloud.google.com/vertex-ai/docs/generative-ai/data-governance)

### Inference window context

Code Suggestions currently inferences against the currently opened file and has a context window of 2,048 tokens and 8,192 character limits. This limit includes content before and after the cursor, the file name, and the extension type.

Learn more about Google Vertex AI [code-gecko](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models).

### Self-managed instance data privacy

A self-managed GitLab instance does not generate the code suggestion. After successful
authentication to the self-managed instance, a token is generated.

The IDE/editor then uses this token to securely transmit data directly to
GitLab.com's Code Suggestions service for processing.

The Code Suggestion service then securely returns an AI-generated code suggestion.

Neither GitLab nor Google Vertex AI Codey APIs have any visibility into a self-managed customer's code other than
what is sent to generate the code suggestion.

### Training data

Code suggestions are routed through Google Vertex AI Codey APIs. Learn more about Google Vertex AI Codey APIs [Data Governance](https://cloud.google.com/vertex-ai/docs/generative-ai/data-governance) and [Responsible AI](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/responsible-ai).

Google Vertex AI Codey APIs are not trained on private non-public GitLab customer or user data.

Google has [shared the following](https://ai.google/discover/foundation-models/) about the data Codey models are trained on:

> Codey is our family of foundational coding models built on PaLM 2. Codey was fine-tuned on a large dataset of high quality, permissively licensed code from external sources

## Progressive enhancement

This feature is designed as a progressive enhancement to developer's IDEs.
Code Suggestions offer a completion if the machine learning engine can generate a recommendation.
In the event of a connection issue or model inference failure, the feature gracefully degrades.
Code Suggestions do not prevent you from writing code in your IDE.

### Internet connectivity

Code Suggestions does not work with offline environments.

To use Code Suggestions:

- On GitLab.com, you must have an internet connection and be able to access GitLab.
- In GitLab 16.1 and later, on self-managed GitLab, you must have an internet connection.

### Model accuracy and quality

Code Suggestions can generate low-quality, incomplete, and possibly insecure code.
We strongly encourage all beta users to leverage GitLab native
[Code Quality Scanning](../../../ci/testing/code_quality.md) and
[Security Scanning](../../application_security/index.md) capabilities.

GitLab currently does not retrain Google Vertex AI Codey APIs. GitLab makes no claims
to the accuracy or quality of code suggestions generated by Google Vertex AI Codey API.
Read more about [Google Vertex AI foundation model capabilities](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models).

## Known limitations

While in Beta, we are working on improving the accuracy of overall generated content.
However, Code Suggestions may generate suggestions that are:

- Low-quality
- Incomplete
- Produce failed pipelines
- Insecure code
- Offensive or insensitive

We are also aware of specific situations that can produce unexpected or incoherent results including:

- Suggestions written in the middle of existing functions, or "fill in the middle."
- Suggestions based on natural language code comments.
- Suggestions that mixed programming languages in unexpected ways.

## Feedback

Report issues in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/405152).

## Troubleshooting

### Code Suggestions aren't displayed

If Code Suggestions are not displayed, try the following troubleshooting steps.

In GitLab, ensure Code Suggestions is enabled:

- [For your user account](#enable-code-suggestions-for-an-individual-user).
- [For *all* top-level groups your account belongs to](../../group/manage.md#enable-code-suggestions). If you don't have a role that lets you view the top-level group's settings, contact a group owner.

To confirm that your account is enabled, go to [https://gitlab.com/api/v4/ml/ai-assist](https://gitlab.com/api/v4/ml/ai-assist). A response of `user_is_allowed` should return `true`.

If you are a self-managed user, ensure that Code Suggestions for the [GitLab WebIDE](../../project/web_ide/index.md) are enabled:

1. On the left sidebar, select **Extensions > GitLab Workflow**.
1. Select **Settings** (**{settings}**), and then select **Extension Settings**.
1. In **GitLab > AI Assisted Code Suggestions**, select the **Enable code completion (Beta)**
   checkbox.

### Authentication troubleshooting

If the above steps do not solve your issue, the problem may be related to the recent changes in authentication,
specifically the token system. To resolve the issue:

1. Remove the existing personal access token from your GitLab account settings.
1. Reauthorize your GitLab account in VS Code using OAuth.
1. Test the code suggestions feature with different file extensions to verify if the issue is resolved.
