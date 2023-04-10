---
stage: ModelOps
group: AI Assisted
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Code Suggestions (Open Beta) **(ULTIMATE)**

> - Enabled as opt-in with GitLab 15.11 as [Open Beta](/ee/policy/alpha-beta-support.md#open-beta-features).
> - [Introduced](https://about.gitlab.com/releases/2023/02/22/gitlab-15-9-released/#code-suggestions-available-in-closed-beta) in GitLab 15.9 as [Closed Beta](/ee/policy/alpha-beta-support.md#closed-beta-features).

WARNING:
This feature is in [Open Beta](/ee/policy/alpha-beta-support.md#open-beta-features). Code Suggestions is a generative AI feature that suggests code for developers. Due to high demand, we expect this feature will have unscheduled downtime and delays in code suggestions appearing in VS Code. We strongly encourage beta users to read about the [known limitations](#known-limitations). We look forward to hearing your feedback.

Use Code Suggestions to code more efficiently by viewing code suggestions
as you type. Depending on the cursor position, the extension either:

- Provides entire code snippets, like generating functions.
- Completes the current line.

You can press <kbd>Tab</kbd> to accept suggestions.

Code Suggestions are supported in Visual Studio Code with the GitLab Workflow extension. GitLab plans to support the [new GitLab WebIDE in an upcoming release](../web_ide_beta/index.md) in the future.

The best results from Code Suggestions are expected for these six languages:

- C
- C++
- Go
- Java
- JavaScript
- Python

Suggestions may be mixed for other languages. Using natural language code comments to request completions may also not function as expected.

GitLab is continuously improving the model and expect to support an additional seven languages soon, as well as natural language code comments.

Usage of Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/). Learn about [data usage when using Code Suggestions](#code-suggestions-data-usage).

## Group level setting **(ULTIMATE)**

[Group owners](../../permissions.md#group-members-permissions) can enable Code Suggestions for all projects in a group by using the [group level Code Suggestions setting](../../group/manage.md#group-code-suggestions).

## Enable Code Suggestions in VS Code **(ULTIMATE)**

Prerequisites:

- Your group owner has enabled the [group level Code Suggestions setting](#group-level-setting).
- You have [created a personal access token](../../profile/personal_access_tokens.md#create-a-personal-access-token) with the `read_api` and `read_user` scopes.

To enable Code Suggestions in VS Code:

1. Download and configure the
   [GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
   for Visual Studio Code.
1. In **GitLab: Add Account to VS Code on Mac**, add your GitLab work account to the VS Code extension:
   - In macOS, press <kbd>Shift</kbd> + <kbd>Command</kbd> + <kbd>P</kbd>.
   - In Windows, press <kbd>Shift</kbd> + <kbd>Control</kbd> + <kbd>P</kbd>.
1. Provide your GitLab instance URL. A default is provided.
1. Provide your personal access token.
1. After your GitLab account connects successfully, in the left sidebar, select **Extensions**.
1. Find the **GitLab workflow** extension, select **Settings** (**{settings}**), and select **Extension Settings**.
1. Enable **GitLab › AI Assisted Code Suggestions**.

Start typing and receive suggestions for your GitLab projects.

<div class="video-fallback">
  See an end-to-end demo: <a href="https://www.youtube.com/watch?v=WnxBYxN2-p4">How to get started with GitLab Code Suggestions in VS Code</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/WnxBYxN2-p4" frameborder="0" allowfullscreen> </iframe>
</figure>

## Code Suggestions Data Usage

### Overview

Code Suggestions is a generative artificial intelligence (AI) model hosted on GitLab.com that can empower your developers to code more efficiently by suggesting code as they type.

This feature uses a VS Code plugin to securely connect to a GitLab API hosted in GitLab.com's enterprise infrastructure that inferences a GitLab managed generative AI model.

#### Enabling the feature

Code Suggestions are managed by a group-level setting that is disabled by default. This group-level setting can only be enabled by group owners.

After the group level setting is enabled, Developers using Visual Studio Code with the [GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) can connect to GitLab.com via a GitLab [personal access token](../../profile/personal_access_tokens.md#create-a-personal-access-token) with the `read_api` and `read_user` scopes.

#### Generating suggestions

Once configured by a developer in VS Code. The personal access token enables a secure API connection to GitLab.com. This API connection securely transmits a context window from VS Code to the Code Suggestions ML model for inference, and the generated suggestion is transmitted back to VS Code.

Code Suggestions only works when developers have internet connectivity and can access GitLab.com. Code Suggestions is not available for self-managed customers, nor customers operating within an air-gapped environment.

### Progressive enhancement

This feature is designed as a progressive enhancement to the existing VS Code GitLab Workflow plugin. Code Suggestions only offers a completion if the ML engine is able to generate a recommendation. In the event of a connection issue or model inference failure, the feature gracefully degrades. At no point with the usage of Code Suggestions prevent a user from being able to write code in VS Code.

### Off by default

Code Suggestions is off by default and requires a Group Owner to enable the feature.

### Stability and performance

This feature is currently marked as [open beta](/ee/policy/alpha-beta-support.md#open-beta-features). While the Code Suggestions inference API operates completely within GitLab.com's enterprise infrastructure, we expect a high demand for this beta feature, which may cause degraded performance or unexpected downtime of the feature. We have built this feature to gracefully degrade and have controls in place to allow us to mitigate abuse or misuse. GitLab may disable this feature for any or all customers at anytime at our discretion.

## Data privacy

Code Suggestions operates completely in the GitLab.com infrastructure, providing the same level of [security](https://about.gitlab.com/security/) as any other feature of GitLab.com, and processing any Personal Data in accordance with our [Privacy Statement](https://about.gitlab.com/privacy/).

No new additional data is collected to enable this feature. The content of your GitLab hosted source code is not used as training data. Source code inference against the Code Suggestions model is not used to re-train the model. Your data also never leaves GitLab.com. All training and inference is done in GitLab.com infrastructure.

[Read more about the security of GitLab.com](https://about.gitlab.com/security/faq/).

### Model Accuracy and quality

We use a customized open source dataset to fine-tune the model to support multiple languages. Based on the languages the developer codes in, we route the request to a targeted inference and prompt engine to get relevant context.

We are actively refining these models to improve the quality of recommendations, add support for more languages, and add protections to limit Personal Data, insecure code, and other unwanted behavior that the model may have learned from training data.

While in beta, it is possible for Code Suggestions to generate low-quality and possibly insecure code. We strongly encourage all beta users to leverage GitLab native [Code Quality Scanning](../../../ci/testing/code_quality.md) and [Security Scanning](../../application_security/index.md) capabilities.

### Training Data

Code Suggestions uses open source pre-trained base models from the [CodeGen family](https://openreview.net/forum?id=iaYcJKpY2B_) including CodeGen-MULTI and CodeGen-NL. We then re-train and fine-tune these base models with a customized open source dataset to enable multi-language support and additional use cases. This customized dataset contains non-preprocessed open source code in 13 programming languages from [The Pile](https://pile.eleuther.ai/) and [Google's BigQuery source code dataset](https://cloud.google.com/blog/topics/public-datasets/github-on-bigquery-analyze-all-the-open-source-code). We then process this raw dataset against heuristics that aim to increase the quality of the dataset.

The Code Suggestions model is not trained on GitLab customer data.

## Known limitations

While in beta, we are working on improving the accuracy of overall generated content. However, Code Suggestions may generate suggestions that are:

- Low-quality
- Incomplete
- Produce failed pipelines
- Insecure code
- Offensive or insensitive

We are also aware of specific situations that can produce unexpected or incoherent results including:

- Suggestions based on natural language code comments.
- Suggestions that mixed programming languages in unexpected ways.

## Feedback

You may report issues in our [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/405152).
