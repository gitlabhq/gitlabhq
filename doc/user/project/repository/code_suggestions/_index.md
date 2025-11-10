---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Code Suggestions helps you write code in GitLab more efficiently by using AI to suggest code as you type.
title: Code Suggestions
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM for code completion: [Fireworks Codestral](https://console.cloud.google.com/vertex-ai/publishers/mistralai/model-garden/codestral-2501) (default), [Vertex AI-hosted Codestral](https://console.cloud.google.com/vertex-ai/publishers/mistralai/model-garden/codestral-2501) For code generation: [Claude Sonnet 4](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- LLM for Amazon Q: Amazon Q Developer
- Available on [GitLab Duo with self-hosted models](../../../../administration/gitlab_duo_self_hosted/_index.md): Yes

{{< /collapsible >}}

{{< history >}}

- [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
- [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
- [Introduced support for Code Generation](https://gitlab.com/gitlab-org/gitlab/-/issues/415583) in GitLab 16.3.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.7.
- [Changed](https://gitlab.com/gitlab-org/fulfillment/meta/-/issues/2031) to require the GitLab Duo Pro add-on on February 15, 2024. Previously, this feature was included with Premium and Ultimate subscriptions.
- [Changed](https://gitlab.com/gitlab-org/fulfillment/meta/-/issues/2031) to require the GitLab Duo Pro or GitLab Duo Enterprise add-on for all supported GitLab versions starting October 17, 2024.
- [Introduced support for Fireworks AI-hosted Qwen2.5 code completion model](https://gitlab.com/groups/gitlab-org/-/epics/15850) in GitLab 17.6, with a flag named `fireworks_qwen_code_completion`.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187397) support for Qwen2.5 code completion model in GitLab 17.11.
- Enabled Fireworks hosted `Codestral` by default via the feature flag `use_fireworks_codestral_code_completion` in GitLab 17.11.
- Changed to include GitLab Duo Core in GitLab 18.0.
- Enabled Fireworks hosted `Codestral` as the default model in GitLab 18.1.
- To opt out of Fireworks for a group, the feature flag `code_completion_opt_out_fireworks` is available.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/545489) the default model for Code Generation to Claude Sonnet 4 in GitLab 18.2.
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) feature flag `code_suggestions_context` in GitLab 18.6.

{{< /history >}}

Use GitLab Duo Code Suggestions to write code more efficiently by using generative AI to suggest code while you're developing.

- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
  [View a click-through demo](https://gitlab.navattic.com/code-suggestions).
  <!-- Video published on 2023-12-09 --> <!-- Demo published on 2024-02-01 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch an overview](https://youtu.be/ds7SG1wgcVM)

## Prerequisites

To use Code Suggestions, you need:

- A GitLab Duo Core, Pro, or Enterprise add-on.
- A Premium or Ultimate subscription.
- If you have GitLab Duo Pro or Enterprise, an assigned seat.
- If you have GitLab Duo Core, [IDE features turned on](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-core-on-or-off).

{{< alert type="note" >}}

GitLab Duo requires GitLab 17.2 or later. For GitLab Duo Core access, and for the best user experience and results,
[upgrade to GitLab 18.0 or later](../../../../update/_index.md). Earlier versions might continue to work, however the experience might be degraded.

{{< /alert >}}

## Use Code Suggestions

Prerequisites:

- You must have [set up Code Suggestions](set_up.md).

To use Code Suggestions:

1. Open your Git project in a [supported IDE](supported_extensions.md#supported-editor-extensions).
1. Add the project as a remote of your local repository using
   [`git remote add`](../../../../topics/git/commands.md#git-remote-add).
1. Add your project directory, including the hidden `.git/` folder, to your IDE workspace or project.
1. Author your code.
   As you type, suggestions are displayed. Code Suggestions provides code snippets
   or completes the current line, depending on the cursor position.

1. Describe the requirements in natural language.
   Code Suggestions generates functions and code snippets based on the context provided.

1. When you receive a suggestion, you can do any of the following:
   - To accept a suggestion, press <kbd>Tab</kbd>.
   - To accept a partial suggestion, press either <kbd>Control</kbd>+<kbd>Right arrow</kbd> or <kbd>Command</kbd>+<kbd>Right arrow</kbd>.
   - To reject a suggestion, press <kbd>Esc</kbd>. In Neovim, press <kbd>Control</kbd>+<kbd>E</kbd> to exit the menu.
   - To ignore a suggestion, keep typing as you usually would.

## View multiple code suggestions

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1325) in GitLab 17.1.

{{< /history >}}

For a code completion suggestion in VS Code, multiple suggestion options
might be available. To view all available suggestions:

1. Hover over the code completion suggestion.
1. Scroll through the alternatives. Either:
   - Use keyboard shortcuts:
     - On a Mac, press <kbd>Option</kbd>+<kbd>\[</kbd> to view the previous suggestion,
       and press <kbd>Option</kbd>+<kbd>]</kbd> to view the next suggestion.
     - On Linux and Windows, press <kbd>Alt</kbd>+<kbd>\[</kbd> to view the previous suggestion,
       and press <kbd>Alt</kbd>+<kbd>]</kbd> to view the next suggestion.
   - On the dialog that's displayed, select the right or left arrow to see next or previous options.
1. Press <kbd>Tab</kbd> to apply the suggestion you prefer.

## Code completion and generation

Code Suggestions uses code completion and code generation:

|  | Code completion | Code generation |
| :---- | :---- | :---- |
| Purpose | Provides suggestions for completing the current line of code.  | Generates new code based on a natural language comment. |
| Trigger | Triggers when typing, usually with a short delay.  | Triggers when pressing <kbd>Enter</kbd> after writing a comment that includes specific keywords. |
| Scope | Limited to the current line or small block of code.  | Can generate entire methods, functions, or even classes based on the context. |
| Accuracy | More accurate for small tasks and short blocks of code.  | Is more accurate for complex tasks and large blocks of code because a bigger large language model (LLM) is used, additional context is sent in the request (for example, the libraries used by the project), and your instructions are passed to the LLM. |
| How to use | Code completion automatically suggests completions to the line you are typing. | You write a comment and press <kbd>Enter</kbd>, or you enter an empty function or method. |
| When to use | Use code completion to quickly complete one or a few lines of code. | Use code generation for more complex tasks, larger codebases, when you want to write new code from scratch based on a natural language description, or when the file you're editing has fewer than five lines of code. |

Code Suggestions always uses both of these features. You cannot use only code
generation or only code completion.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[View a code completion vs. code generation comparison demo](https://www.youtube.com/watch?v=9dsyqMt9yg4).
<!-- Video published on 2024-09-26 -->

### Best practices for code generation

To get the best results from code generation:

- Be as specific as possible while remaining concise.
- State the outcome you want to generate (for example, a function)
  and provide details on what you want to achieve.
- Add additional information, like the framework or library you want to use.
- Add a space or new line after each comment.
  This space tells the code generator that you have completed your instructions.
- In GitLab 17.2 and later, when the `advanced_context_resolver` and `code_suggestions_context`
  feature flags are enabled, open related files in other tabs to expand the
  [context that Code Suggestions is aware of](../../../gitlab_duo/context.md#code-suggestions).
- [Removed](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) feature flag `code_suggestions_context` in GitLab 18.6.

For example, to create a Python web service with some specific requirements,
you might write something like:

```plaintext
# Create a web service using Tornado that allows a user to sign in, run a security scan, and review the scan results.
# Each action (sign in, run a scan, and review results) should be its own resource in the web service
...
```

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

For use cases and best practices, follow the [GitLab Duo examples documentation](../../../gitlab_duo/use_cases.md).

## Truncation of file content

Because of LLM limits and performance reasons, the content of the currently
opened file is truncated:

- For code completion: to 32,000 tokens (roughly 128,000 characters).
- For code generation: to 200,000 tokens (roughly 800,000 characters).

Content above the cursor is prioritized over content below the cursor. The content
above the cursor is truncated from the left side, and content below the cursor
is truncated from the right side. These numbers represent the maximum input context
size for Code Suggestions.

## Output length

Because of LLM limits and for performance reasons, the output of Code Suggestions
is limited:

- For code completion: to 64 tokens (roughly 256 characters).
- For code generation: to 2048 tokens (roughly 7168 characters).

## Accuracy of results

We are continuing to work on the accuracy of overall generated content.
However, Code Suggestions might generate suggestions that are:

- Irrelevant.
- Incomplete.
- Results in failed pipelines.
- Potentially insecure.
- Offensive or insensitive.

When using Code Suggestions, code review best practices still apply.

## Available language models

Different language models can be the source for Code Suggestions.

- On GitLab.com: GitLab hosts the models and connects to them through the cloud-based AI gateway.
- On GitLab Self-Managed, two options exist:
  - GitLab can [host the models and connects to them through the cloud-based AI gateway](set_up.md).
  - Your organization can [use GitLab Duo Self-Hosted](../../../../administration/gitlab_duo_self_hosted/_index.md),
    which means you host the AI gateway and language models. You can use GitLab AI vendor models,
    other supported language models, or to bring your own compatible model.

## How the prompt is built

To learn about the code that builds the prompt, see these files:

- Code generation:
  [`ee/lib/api/code_suggestions.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/code_suggestions.rb#L76)
  in the `gitlab` repository.
- Code completion:
  [`ai_gateway/code_suggestions/processing/completions.py`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/fcb3f485a8f047a86a8166aad81f93b6d82106a7/ai_gateway/code_suggestions/processing/completions.py#L273)
  in the `modelops` repository.

## Prompt caching

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/535651) in GitLab 18.0.

{{< /history >}}

Prompt caching is enabled by default to improve Code Suggestions latency. When prompt caching is enabled, code completion prompt data is temporarily stored in memory by the model vendor. Prompt caching significantly improves latency by avoiding the re-processing of cached prompt and input data. The cached data is never logged to any persistent storage.

### Disable prompt caching

You can disable prompt caching for top-level groups in the GitLab Duo settings.

On GitLab.com:

1. On the left sidebar, select **Search or go to** and find your group. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings** > **GitLab Duo**.
1. Select **Change configuration**.
1. Disable the **Prompt caching** toggle.
1. Select **Save changes**.

On GitLab Self-Managed:

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **GitLab Duo**.
1. Select **Change Configuration**.
1. Under **Prompt Cache**, clear the **Turn on prompt caching** checkbox.
1. Select **Save changes**.

## Response time

Code Suggestions is powered by a generative AI model.

- For code completion, suggestions are usually low latency and take less than one second.
- For code generation, algorithms or large code blocks might take more than five seconds to generate.

Your personal access token enables a secure API connection to GitLab.com or to your GitLab instance.
This API connection securely transmits a context window from your IDE/editor to the [GitLab AI gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), a GitLab hosted service. The gateway calls the large language model APIs, and then the generated suggestion is transmitted back to your IDE/editor.

### Streaming

Streaming of Code Generation responses is supported in JetBrains and Visual Studio, leading to
perceived faster response times.
Other supported IDEs will return the generated code in a single block.

Streaming is not enabled for code completion.

### Direct and indirect connections

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462791) in GitLab 17.2 [with a flag](../../../../administration/feature_flags/_index.md) named `code_suggestions_direct_access`. Disabled by default.

{{< /history >}}

By default, code completion requests are sent from the IDE directly to the AI gateway to minimize the latency.
For this direct connection to work, the IDE must be able to connect to `https://cloud.gitlab.com:443`. If this is not
possible (for example, because of network restrictions), you can disable direct connections for all users. If you do this,
code completion requests are sent indirectly through the GitLab Self-Managed instance, which in turn sends the requests
to the AI gateway. This might result in your requests having higher latency.

#### Configure direct or indirect connections

Prerequisites:

- You must be an administrator for the GitLab Self-Managed instance.

{{< tabs >}}

{{< tab title="In 17.4 and later" >}}

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **GitLab Duo features**.
1. Under **Connection method**, choose an option:
   - To minimize latency for code completion requests, select **Direct connections**.
   - To disable direct connections for all users, select **Indirect connections through the GitLab Self-Managed instance**.
1. Select **Save changes**.

{{< /tab >}}

{{< tab title="In 17.3 and earlier" >}}

1. On the left sidebar, at the bottom, select **Admin**. If you've [turned on the new navigation](../../../interface_redesign.md#turn-new-navigation-on-or-off), in the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. Expand **AI-native features**.
1. Choose an option:
   - To enable direct connections and minimize latency for code completion requests, clear the **Disable direct connections for code suggestions** checkbox.
   - To disable direct connections, select the **Disable direct connections for code suggestions** checkbox.

{{< /tab >}}

{{< /tabs >}}

## Feedback

Provide feedback about your Code Suggestions experience in [issue 435783](https://gitlab.com/gitlab-org/gitlab/-/issues/435783).
