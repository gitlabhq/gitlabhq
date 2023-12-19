---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Code Suggestions **(FREE ALL BETA)**

> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - [Introduced support for Code Generation](https://gitlab.com/gitlab-org/gitlab/-/issues/415583) in GitLab 16.3.

WARNING:
This feature is in [Beta](../../../../policy/experiment-beta-support.md#beta).
Beta users should read about the [known limitations](#known-limitations). We look forward to hearing your [feedback](#feedback).

Write code more efficiently by using generative AI to suggest code while you're developing.

With Code Suggestions, you get:

- Code Completion, which suggests completions the current line you are typing. These suggestions are usually low latency.
- Code Generation, which generates code based on a natural language code comment block. Generating code can exceed multiple seconds.

## Start using Code Suggestions

GitLab Duo Code Suggestions are available:

- On [self-managed](self_managed.md) and [SaaS](saas.md). View these pages to get started.
- In VS Code, Microsoft Visual Studio, JetBrains IDEs, and Neovim. You must have the corresponding GitLab extension installed.
- In the GitLab Web IDE.

<div class="video-fallback">
  <a href="https://youtu.be/wAYiy05fjF0">View how to setup and use GitLab Duo Code Suggestions</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/wAYiy05fjF0" frameborder="0" allowfullscreen> </iframe>
</figure>

During Beta, usage of Code Suggestions is governed by the [GitLab Testing Agreement](https://about.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using Code Suggestions](#code-suggestions-data-usage). As Code Suggestions matures to General Availability it will be governed by our [AI Functionality Terms](https://about.gitlab.com/handbook/legal/ai-functionality-terms/).

## Supported languages

Code Suggestions support is a function of the:

- Underlying large language model.
- IDE used.
- Extension or plug-in support in the IDE.

For languages not listed in the following table, Code Suggestions might not function as expected.

### Supported languages in IDEs

Editor support for languages is documented in the following table.

| Language         | VS Code                | JetBrains IDEs         | Visual Studio          | Neovim |
|------------------|------------------------|------------------------|------------------------|--------|
| C++              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| C#               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Go               | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Google SQL       | **{dotted-circle}** No | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Java             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| JavaScript       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Kotlin           | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| PHP              | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Python           | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Ruby             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Rust             | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Scala            | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Swift            | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| TypeScript       | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes | **{check-circle}** Yes |
| Google Cloud     | **{dotted-circle}** No | **{dotted-circle}** No | **{dotted-circle}** No | **{dotted-circle}** No |
| Kubernetes Resource Model (KRM) | **{dotted-circle}** No | **{dotted-circle}** No | **{dotted-circle}** No | **{dotted-circle}** No |
| Terraform        | **{check-circle}** Yes (Requires third-party extension providing Terraform support) | **{check-circle}** Yes | **{dotted-circle}** No | **{check-circle}** Yes (Requires third-party extension providing the `terraform` file type) |

NOTE:
Some languages are not supported in all JetBrains IDEs, or may require additional
plugin support. Refer to the JetBrains documentation for specifics on your IDE.

## Supported editor extensions

Code Suggestions supports a variety of popular editors including:

- VS Code, using [the VS Code GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow).
- [GitLab WebIDE (VS Code in the Cloud)](../../../project/web_ide/index.md), with no additional configuration.
- Microsoft Visual Studio, using the [Visual Studio GitLab extension](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio).
- JetBrains IDEs, using the [GitLab plugin](https://plugins.jetbrains.com/plugin/22325-gitlab).
- Neovim, using the [`gitlab.vim` plugin](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim).

A [GitLab Language Server for Code Suggestions](https://gitlab.com/gitlab-org/editor-extensions/gitlab-language-server-for-code-suggestions)
is also in process.
This improvement should result in:

- Faster iteration and standardization of the IDE extensions.
- The ability to use Code Suggestions even when an official editor extension isn't available.

## Code Suggestions data usage

Code Suggestions is powered by a generative AI model.

Your personal access token enables a secure API connection to GitLab.com or to your GitLab instance.
This API connection securely transmits a context window from your IDE/editor to the [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), a GitLab hosted service. The [gateway](../../../../development/ai_architecture.md) calls the large language model APIs, and then the generated suggestion is transmitted back to your IDE/editor.

GitLab selects the best-in-class large-language models for specific tasks. We use [Google Vertex AI Code Models](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview) and [Anthropic Claude](https://www.anthropic.com/product) for Code Suggestions.

[View data retention policies](../../../ai_features.md#data-retention).

### Telemetry

For self-managed instances that have enabled Code Suggestions and SaaS accounts, we collect aggregated or de-identified first-party usage data through our [Snowplow collector](https://about.gitlab.com/handbook/business-technology/data-team/platform/snowplow/). This usage data includes the following metrics:

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

## Known limitations

While in Beta, we are working on improving the accuracy of overall generated content.
However, Code Suggestions may generate suggestions that are:

- Low-quality
- Incomplete
- Produce failed pipelines
- Insecure code
- Offensive or insensitive

## Progressive enhancement

This feature is designed as a progressive enhancement to developer's IDEs.
Code Suggestions offer a completion if a suitable recommendation is provided to the user in a timely matter.
In the event of a connection issue or model inference failure, the feature gracefully degrades.
Code Suggestions do not prevent you from writing code in your IDE.

## Feedback

Report issues in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/405152).
