---
stage: AI-powered
group: AI Model Validation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Code Suggestions **(FREE ALL BETA)**

> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.

WARNING:
This feature is in [Beta](../../../../policy/experiment-beta-support.md#beta).
Beta users should read about the [known limitations](#known-limitations). We look forward to hearing your [feedback](#feedback).

Write code more efficiently by using generative AI to suggest code while you're developing.

Code Suggestions are available:

- On [self-managed](self_managed.md) and [SaaS](saas.md).
- In VS Code, Microsoft Visual Studio, JetBrains IDEs, and Neovim. You must have the corresponding GitLab extension installed.
- In the GitLab WebIDE.

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

### Supported code infrastructure interfaces

Code Suggestions includes [Google Vertex AI Codey APIs](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview#supported_code_infrastructure_interfaces) support for the following infrastructure as code interfaces:

- Google Cloud CLI
- Kubernetes Resource Model (KRM)
- Terraform

Suggestion quality for other languages and using natural language code comments to request completions may not yet result in high-quality suggestions.

### Supported languages in IDEs

Editor support for languages is documented in the following table.

| Language                        | VS Code                                                      | JetBrains IDEs               | Visual Studio | Neovim |
|---------------------------------|--------------------------------------------------------------|------------------------------|---------------|--------|
| C++                             | ✓                                                            |                              | ✓             |        |
| C#                              | ✓                                                            | ✓                            | ✓             |        |
| Go                              | ✓                                                            | ✓ (IDEA Ultimate / GoLand)   | ✓             |        |
| Google SQL                      |                                                              |                              | ✓             |        |
| Java                            | ✓                                                            | ✓                            | ✓             |        |
| JavaScript                      | ✓                                                            | ✓                            | ✓             |        |
| Kotlin                          | ✓                                                            | ✓                            | ✓             |        |
| PHP                             | ✓                                                            | ✓ (IDEA Ultimate)            | ✓             |        |
| Python                          | ✓                                                            | ✓                            | ✓             | ✓      |
| Ruby                            | ✓                                                            | ✓ (IDEA Ultimate / RubyMine) | ✓             | ✓      |
| Rust                            | ✓                                                            | ✓                            | ✓             |        |
| Scala                           | ✓                                                            | ✓                            | ✓             |        |
| Swift                           | ✓                                                            | ✓                            | ✓             |        |
| TypeScript                      | ✓                                                            | ✓                            | ✓             |        |
| Google Cloud CLI                |                                                              |                              |               |        |
| Kubernetes Resource Model (KRM) |                                                              |                              |               |        |
| Terraform                       | ✓ (Requires 3rd party extension providing Terraform support) |                              |               |        |

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

Code Suggestions is a generative artificial intelligence (AI) model.

Your personal access token enables a secure API connection to GitLab.com.
This API connection securely transmits a context window from your IDE/editor to the Code Suggestions GitLab hosted service which calls Google Vertex AI Codey APIs,
and the generated suggestion is transmitted back to your IDE/editor.

GitLab currently leverages [Google Cloud's Vertex AI Codey API models](https://cloud.google.com/vertex-ai/docs/generative-ai/code/code-models-overview). Learn more about Google Vertex AI Codey APIs [Data Governance](https://cloud.google.com/vertex-ai/docs/generative-ai/data-governance).

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

Code Suggestions currently inferences against the currently opened file and has a context window of 2,048 tokens and 8,192 character limits. This limit includes content before and after the cursor, the file name, and the extension type.
Learn more about Google Vertex AI [code-gecko](https://cloud.google.com/vertex-ai/docs/generative-ai/learn/models).

The maximum number of tokens that is generated in the response is default 64. A token is approximately four characters. 100 tokens correspond to roughly 60-80 words.
Learn more about Google Vertex AI [`code-gecko`](https://cloud.google.com/vertex-ai/docs/generative-ai/model-reference/code-completion).

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
[Code Quality Scanning](../../../../ci/testing/code_quality.md) and
[Security Scanning](../../../application_security/index.md) capabilities.

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
