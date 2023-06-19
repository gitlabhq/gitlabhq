---
stage: ModelOps
group: AI Assisted
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Code Suggestions (Beta) **(FREE SAAS)**

> - [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Beta](/ee/policy/experiment-beta-support.md#beta) for early access Ultimate customers.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/408104) as opt-in with GitLab 15.11 as [Beta](/ee/policy/experiment-beta-support.md#beta).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/408158) from GitLab Ultimate to GitLab Premium in 16.0.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/410801) from GitLab Premium to GitLab Free in 16.0.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1.
> - [Default to third-party AI services](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.

WARNING:
This feature is in [Beta](/ee/policy/experiment-beta-support.md#beta).
Due to high demand, this feature may have unscheduled downtime and Code Suggestions in IDEs may be delayed.
Code Suggestions may produce [low-quality or incomplete suggestions](#model-accuracy-and-quality).
Beta users should read about the [known limitations](#known-limitations). We look forward to hearing your feedback.

Code Suggestions use generative AI to suggest code while you're developing.
Use Code Suggestions to write code more efficiently by viewing Code Suggestions
as you type. Depending on the cursor position, the extension either:

- Provides entire code snippets, like generating functions.
- Completes the current line.

To accept a suggestion, press <kbd>Tab</kbd>.

Code Suggestions are available in Visual Studio Code when you have the GitLab Workflow extension installed. [Additional IDE extension support](https://gitlab.com/groups/gitlab-org/-/epics/10542) is planned for the near future.

## Supported languages

Code Suggestions may produce [low-quality or incomplete suggestions](#model-accuracy-and-quality).

Language support varies depending on which AI model serves Code Suggestions. To use Code Suggestions entirely within GitLab cloud infrastructure, disable third-party AI services. To receive higher quality suggestions, [enable third-party AI services](#third-party-ai-services-controls).

The best results from Code Suggestions are expected for these languages:

- **Third-party AI services (Google Codey)**: Go, Google Cloud CLI, Google SQL, Java, JavaScript, Kubernetes Resource Model (KRM), Python, Terraform, TypeScript.
- **GitLab first-party AI model**: C/C++, C#, Go, Java, JavaScript, Python, PHP, Ruby, Rust, Scala, TypeScript.

Suggestions may be mixed for other languages. Using natural language code comments to request completions may also not function as expected.

Suggestions are best when writing new code. Editing existing functions or 'fill in the middle' of a function may not perform as expected.

We are making improvements to the Code Suggestions underlying AI model weekly to improve the quality of suggestions. Please remember that AI is non-deterministic, so you may not get the same suggestion week to week.

Usage of Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/). Learn about [data usage when using Code Suggestions](#code-suggestions-data-usage).

## Enable Code Suggestions for an individual user

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/121079) in GitLab 16.1 as [Beta](/ee/policy/experiment-beta-support.md#beta).

Each user can enable Code Suggestions for themselves:

1. On the left sidebar, select your avatar.
1. On the left sidebar, select **Preferences**.
1. In the **Code Suggestions** section, select **Enable Code Suggestions**.
1. Select **Save changes**.

NOTE:
If Code Suggestions is [enabled for the group](../../group/manage.md#enable-code-suggestions), the group setting overrides the user setting.

## Enable Code Suggestions in WebIDE

Prerequisites:

- Code Suggestions must be [enabled for the top-level group](../../group/manage.md#enable-code-suggestions).
- Code Suggestions must be [enabled for your user account](#enable-code-suggestions-for-an-individual-user).
- You must be a GitLab team member.

Code Suggestions work automatically in the [GitLab WebIDE](../../project/web_ide/index.md) if the above prerequisites are met. To disable Code Suggestions in the WebIDE, disable the user account setting.

NOTE:
Disabling in the WebIDE will also disable in any other IDEs you use locally like VS Code. Support for [more granular control per IDE](https://gitlab.com/groups/gitlab-org/-/epics/10624) is proposed.

## Enable Code Suggestions in VS Code

Prerequisites:

- Code Suggestions must be [enabled for the top-level group](../../group/manage.md#enable-code-suggestions).
- Code Suggestions must be [enabled for your user account](#enable-code-suggestions-for-an-individual-user).
- Completed the [setup instructions](https://gitlab.com/gitlab-org/gitlab-vscode-extension#setup) for the GitLab Visual Studio Code Extension.

To enable Code Suggestions in VS Code:

1. Download and install the
   [GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
   for Visual Studio Code.
1. Complete the [setup instructions](https://gitlab.com/gitlab-org/gitlab-vscode-extension#setup) for the extension.
1. After your GitLab account connects successfully, in the left sidebar, select **Extensions**.
1. Find the **GitLab workflow** extension, select **Settings** (**{settings}**), and select **Extension Settings**.
1. Enable **GitLab > AI Assisted Code Suggestions**.

Start typing and receive suggestions for your GitLab projects.

<div class="video-fallback">
  See an end-to-end demo: <a href="https://www.youtube.com/watch?v=WnxBYxN2-p4">Get started with GitLab Code Suggestions in VS Code</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/WnxBYxN2-p4" frameborder="0" allowfullscreen> </iframe>
</figure>

## Enable Code Suggestions in other IDEs and editors

We have experimental support for Code Suggestions in Visual Studio, JetBrains, Neovim, Emacs, Sublime, etc.

More details in this [blog](https://about.gitlab.com/blog/2023/06/01/extending-code-suggestions/).

## Why aren't Code Suggestions displayed?

If Code Suggestions are not displayed, try the following troubleshooting steps.

In GitLab, ensure Code Suggestions is enabled:

- [For your user account](#enable-code-suggestions-for-an-individual-user).
- [For *all* top-level groups your account belongs to](../../group/manage.md#enable-code-suggestions). If you don't have a role that lets you view the top-level group's settings, contact a group owner.

In VS Code:

- Ensure [your IDE is configured properly](#enable-code-suggestions-in-vs-code).

To confirm that your account is enabled, go to [https://gitlab.com/api/v4/ml/ai-assist](https://gitlab.com/api/v4/ml/ai-assist). A response of `user_is_allowed` should return `true`.

### Authentication troubleshooting

If the above steps do not solve your issue, the problem may be related to the recent changes in authentication, specifically the token system. To resolve the issue, please follow these troubleshooting steps:

- Remove the existing PAT from your GitLab account settings.
- Reauthorize your GitLab account in VSCode using OAuth.
- Test the code suggestions feature with different file extensions to verify if the issue is resolved.

## Third-party AI services controls

Organizations can opt to use Code Suggestions entirely within GitLab cloud infrastructure. This option can be controlled with the top-level group [Third-party AI setting](../../group/manage.md#enable-third-party-ai-features).

Having the third-party AI setting enabled will allow Code Suggestions to use third-party AI services, which is likely to produce higher quality results. Please note that language support varies between the two options and will change over time.

To use Code Suggestions entirely within GitLab’s cloud infrastructure, disable third-party AI services. You can disable Code Suggestions entirely in [your user profile settings](#enable-code-suggestions-for-an-individual-user).

## Stability and performance

This feature is currently in [Beta](/ee/policy/experiment-beta-support.md#beta).
While the Code Suggestions inference API operates completely within the GitLab.com enterprise infrastructure,
we expect a high demand for this Beta feature, which may cause degraded performance or unexpected downtime
of the feature. We have built this feature to gracefully degrade and have controls in place to allow us to
mitigate abuse or misuse. GitLab may disable this feature for any or all customers at any time at our discretion.

## Code Suggestions data usage

Code Suggestions is a generative artificial intelligence (AI) model hosted on GitLab.com.

Your personal access token enables a secure API connection to GitLab.com.
This API connection securely transmits a context window from VS Code to the Code Suggestions ML model for inference,
and the generated suggestion is transmitted back to VS Code.

Depending on your settings, different ML models will be used to provide Code Suggestions. GitLab currently leverages [Google Cloud's Vertex AI Codey API models](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview) for third-party AI powered Code Suggestions. The sections below refer only to GitLab first-party AI Model.

### Data privacy

This section applies only to customers who have third-party AI services disabled.

Code Suggestions operate completely in the GitLab.com infrastructure, providing the same level of
[security](https://about.gitlab.com/security/) as any other feature of GitLab.com, and processing any personal
data in accordance with our [Privacy Statement](https://about.gitlab.com/privacy/).

No new additional data is collected to enable this feature. The content of your GitLab hosted source code is
not used as training data. Source code inference against the Code Suggestions model is not used to re-train the model.
Your data also never leaves GitLab.com. All training and inference is done in GitLab.com infrastructure.

[Read more about the security of GitLab.com](https://about.gitlab.com/security/faq/).

### Training data

This section applies only to customers who have third-party AI services disabled.

Code Suggestions uses open source pre-trained base models from the
[CodeGen family](https://openreview.net/forum?id=iaYcJKpY2B_) including CodeGen-MULTI and CodeGen-NL.
We then re-train and fine-tune these base models with a customized open source dataset to enable multi-language
support and additional use cases. This customized dataset contains non-preprocessed open source code in 13
programming languages from [The Pile](https://pile.eleuther.ai/) and the
[Google BigQuery source code dataset](https://cloud.google.com/blog/topics/public-datasets/github-on-bigquery-analyze-all-the-open-source-code).
We then process this raw dataset against heuristics that aim to increase the quality of the dataset.

The Code Suggestions model is not trained on GitLab customer or user data.

## Progressive enhancement

This feature is designed as a progressive enhancement to developers IDEs.
Code Suggestions offer a completion if the machine learning engine can generate a recommendation.
In the event of a connection issue or model inference failure, the feature gracefully degrades.
Code Suggestions do not prevent you from writing code in your IDE.

### Internet connectivity

Code Suggestions does not work with offline environments.

To use Code Suggestions:

- On GitLab.com, you must have an internet connection and be able to access GitLab.
- In GitLab 16.1 and later, on self-managed GitLab, you must have an internet connection.

[Self-managed support via a proxy to GitLab.com](https://gitlab.com/groups/gitlab-org/-/epics/10528) has been proposed.

### Model accuracy and quality

Regardless of whether third-party AI services are enabled, while in Beta, Code Suggestions can generate low-quality, incomplete, and possibly insecure code.
We strongly encourage all beta users to leverage GitLab native
[Code Quality Scanning](../../../ci/testing/code_quality.md) and
[Security Scanning](../../application_security/index.md) capabilities.

GitLab uses a customized open source dataset to fine-tune the model to support multiple languages.
Based on the languages you code in, GitLab routes the request to a targeted inference and prompt engine
to get relevant suggestions.

GitLab is actively refining these models to:

- Improve the quality of recommendations.
- Add support for more languages.
- Add protections to limit personal data, insecure code, and other unwanted behavior
  that the model may have learned from training data.

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
