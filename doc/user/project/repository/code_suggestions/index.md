---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions

> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - [Introduced support for Code Generation](https://gitlab.com/gitlab-org/gitlab/-/issues/415583) in GitLab 16.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.7.

Write code more efficiently by using generative AI to suggest code while you're developing.

With GitLab Duo Code Suggestions, you get:

- Code completion, which suggests completions to the current line you are typing.
- Code generation, which generates code based on a natural language code
  comment block. Write a comment like `# Type more here`, then press <kbd>Enter</kbd> to generate
  code based on the context of your comment and the rest of your code.

Get started with Code Suggestions on your [self-managed](self_managed.md) instance
or on [SaaS](saas.md).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[Watch a video overview](https://youtu.be/xQUlrbIWo8o).
<!-- Video published on 2023-12-09 -->

## Required subscription

Code Suggestions availability is changing.

Access subject to the [Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/)
is available through February 14, 2024:

- For SaaS, on all subscription tiers (Free, Premium, and Ultimate).
- For self-managed, on Premium and Ultimate tiers.

Starting February 15, 2024, Code Suggestions will be part of [GitLab Duo Pro](https://about.gitlab.com/gitlab-duo/):

- GitLab Duo Pro is available for both SaaS and self-managed, on Premium and Ultimate tiers.

NOTE:
On February 15th, if you have not purchased GitLab Duo Pro,
you will no longer have access to Code Suggestions.
Get access by
[contacting your sales team and assigning seats to the users who want access](../../../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-pro-seats).

Code Suggestions are not available for the GitLab Community Edition.

## Supported editor extensions

To use Code Suggestions, use one of these editor extensions:

| IDE              | Extension              |
|------------------|------------------------|
| VSCode           | [VS Code GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)|
| [GitLab WebIDE (VS Code in the Cloud)](../../../project/web_ide/index.md)  | No configuration required. |
| Microsoft Visual Studio | [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio) |
 JetBrains IDEs  | [GitLab plugin](https://plugins.jetbrains.com/plugin/22325-gitlab) |
 Neovim           | [`gitlab.vim` plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim) |

A [GitLab Language Server](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp) is used in VS Code, Visual Studio, and Neovim. The Language Server supports faster iteration across more platforms. You can also configure it to support Code Suggestions in IDEs where GitLab doesn't provide official support.

## Supported languages

Code Suggestions is aware of common popular programming languages, concepts, and
infrastructure-as-code interfaces, like Kubernetes Resource Model (KRM),
Google Cloud CLI, and Terraform.

The following languages are supported:

| Language         | VS Code                | JetBrains IDEs         | Visual Studio          | Neovim |
|------------------|------------------------|------------------------|------------------------|--------|
| C++              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| C#               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| CSS              | **{check-circle}** No  | **{check-circle}** Yes | **{check-circle}** No  | **{check-circle}** No  |
| Go               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Google SQL       | **{dotted-circle}** No | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| HTML             | **{check-circle}** No  | **{check-circle}** Yes | **{check-circle}** No  | **{check-circle}** No  |
| Java             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| JavaScript       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Kotlin           | **{check-circle}** Yes <br><br>(Requires third-party extension providing Kotlin support) | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| PHP              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Python           | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Ruby             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Rust             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Scala            | **{check-circle}** Yes <br><br>(Requires third-party extension providing Scala support) | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Shell scripts (`bash` only) | **{check-circle}** No  | **{check-circle}** Yes | **{check-circle}** No  | **{check-circle}** No  |
| Swift            | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| TypeScript       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Terraform        | **{check-circle}** Yes <br><br>(Requires third-party extension providing Terraform support) | **{check-circle}** Yes | **{dotted-circle}** No | **{check-circle}** Yes <br><br>(Requires third-party extension providing the `terraform` file type) |

NOTE:
Some languages are not supported in all JetBrains IDEs, or might require additional
plugin support. Refer to the JetBrains documentation for specifics on your IDE.

For languages not listed in the table, Code Suggestions might not function as expected.

## Response time

- Code completion suggestions are usually low latency.
- For code generation:
  - Algorithms or large code blocks might take more than 10 seconds to generate.
  - Streaming of code generation responses is supported in VS Code, leading to faster average response times. Other supported IDEs offer slower response times and will return the generated code in a single block.

## Data usage

Code Suggestions is powered by a generative AI model.

Your personal access token enables a secure API connection to GitLab.com or to your GitLab instance.
This API connection securely transmits a context window from your IDE/editor to the [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), a GitLab hosted service. The [gateway](../../../../development/ai_architecture.md) calls the large language model APIs, and then the generated suggestion is transmitted back to your IDE/editor.

GitLab selects the best-in-class large-language models for specific tasks. We use [Google Vertex AI Code Models](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview) and [Anthropic Claude](https://www.anthropic.com/product) for Code Suggestions.

[View data retention policies](../../../ai_features.md#data-retention).

### Telemetry

For self-managed instances that have enabled Code Suggestions and for SaaS accounts, we collect aggregated or de-identified first-party usage data through our [Snowplow collector](https://handbook.gitlab.com/handbook/business-technology/data-team/platform/snowplow/). This usage data includes the following metrics:

- Language the code suggestion was in (for example, Python)
- Editor being used (for example, VS Code)
- Number of suggestions shown, accepted, rejected, or that had errors
- Duration of time that a suggestion was shown
- Prompt and suffix lengths
- Model used
- Number of unique users
- Number of unique instances

### Inference window context

Code Suggestions inferences against the currently opened file, the content before and after the cursor, the filename, and the extension type. For more information on possible future context expansion to improve the quality of suggestions, see [epic 11669](https://gitlab.com/groups/gitlab-org/-/epics/11669).

### Training data

GitLab does not train generative AI models based on private (non-public) data. The vendors we work with also do not train models based on private data.

For more information on GitLab Code Suggestions data [sub-processors](https://about.gitlab.com/privacy/subprocessors/#third-party-sub-processors), see:

- Google Vertex AI Codey APIs [data governance](https://cloud.google.com/vertex-ai/docs/generative-ai/data-governance) and [responsible AI](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/responsible-ai).
- Anthropic Claude's [constitution](https://www.anthropic.com/index/claudes-constitution).

## Accuracy of results

We are continuing to work on the accuracy of overall generated content.
However, Code Suggestions might generate suggestions that are:

- Irrelevant.
- Incomplete.
- Results in failed pipelines.
- Potentially insecure.
- Offensive or insensitive.

When using Code Suggestions, [code review best practice](../../../../development/code_review.md) still applies.

## Progressive enhancement

This feature is designed as a progressive enhancement to developer IDEs.
Code Suggestions offer a completion if a suitable recommendation is provided to the user in a timely matter.
In the event of a connection issue or model inference failure, the feature gracefully degrades.
Code Suggestions do not prevent you from writing code in your IDE.

## Disable Code Suggestions

To disable Code Suggestions, disable the feature in your IDE editor extension.

## Feedback

Provide feedback about your Code Suggestions experience in [issue 435783](https://gitlab.com/gitlab-org/gitlab/-/issues/435783).
