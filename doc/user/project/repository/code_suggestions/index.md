---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Code Suggestions helps you write code in GitLab more efficiently by using AI to suggest code as you type."
---

# Code Suggestions

DETAILS:
**Tier:** Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../../../subscriptions/subscription-add-ons.md)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - [Introduced support for Code Generation](https://gitlab.com/gitlab-org/gitlab/-/issues/415583) in GitLab 16.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.7.
> - Subscription changed to require GitLab Duo Pro on February 15, 2024.

NOTE:
GitLab Duo requires GitLab 17.2 and later for the best user experience and results. Earlier versions may continue to work, however the experience may be degraded.

Write code more efficiently by using generative AI to suggest code while you're developing.

With GitLab Duo Code Suggestions, you get code completion and code generation.

## Code completion

Code completion suggests completions to the line you are typing.
Code completion is used in most situations to quickly complete one
or a few lines of code.

## Code generation

Code generation generates code based on a natural language code
comment block. Write a comment like `# check if code suggestions are
enabled for current user`, then press <kbd>Enter</kbd> to generate code based
on the context of your comment and the rest of your code.

Code generation is used when:

- You write a comment and press <kbd>Enter</kbd>.
- You enter an empty function or method.
- The file you're editing has fewer than five lines of code.

Code generation requests take longer than code completion requests, but provide more accurate responses because:

- A larger LLM is used.
- Additional context is sent in the request, for example, the libraries used by the project.
- Your instructions are passed to the LLM.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[View a click-through demo](https://gitlab.navattic.com/code-suggestions).
<!-- Video published on 2023-12-09 --> <!-- Demo published on 2024-02-01 -->

## Use Code Suggestions

Prerequisites:

- You must have [one of the supported IDE extensions](supported_extensions.md#supported-editor-extensions).
- Your organization must have purchased the GitLab Duo Pro add-on and
  [assigned you a seat](../../../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- For self-managed GitLab, you must have GitLab 16.8 or later, and have
  [configured proxy settings](../../../../subscriptions/subscription-add-ons.md#configure-network-and-proxy-settings).

To use Code Suggestions:

1. Open your Git project in a supported IDE.
1. Add the project as a remote of your local repository using
   [`git remote add`](../../../../topics/git/commands.md#git-remote-add).
1. Add your project directory, including the hidden `.git/` folder, to your IDE workspace or project.
1. Author your code.
   As you type, suggestions are displayed. Code Suggestions provides code snippets
   or completes the current line, depending on the cursor position.

1. Describe the requirements in natural language.
   Code Suggestions generates functions and code snippets based on the context provided.

1. To accept a suggestion, press <kbd>Tab</kbd>. To reject a suggestion, press <kbd>Esc</kbd>.
1. To ignore a suggestion, keep typing as you usually would.

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

## Best practices

To get the best results from code generation:

- Be as specific as possible while remaining concise.
- State the outcome you want to generate (for example, a function)
  and provide details on what you want to achieve.
- Add additional information, like the framework or library you want to use.
- Add a space or new line after each comment.
  This space tells the code generator that you have completed your instructions.
- In GitLab 17.2 and later, when the `advanced_context_resolver` and `code_suggestions_context`
  feature flags are enabled, open related files in other tabs to expand the
  [inference window context](#inference-window-context).

For example, to create a Python web service with some specific requirements,
you might write something like:

```plaintext
# Create a web service using Tornado that allows a user to sign in, run a security scan, and review the scan results.
# Each action (sign in, run a scan, and review results) should be its own resource in the web service
...
```

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

### Best practice examples

For use cases and best practices, follow the [GitLab Duo examples documentation](../../../gitlab_duo_examples.md).

#### Use open tabs as context

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464767) in GitLab 17.2 [with a flag](../../../../administration/feature_flags.md) named `advanced_context_resolver`. Disabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) in GitLab 17.2 [with a flag](../../../../administration/feature_flags.md) named `code_suggestions_context`. Disabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/276) in GitLab Workflow for VS Code 4.20.0.
> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/462) in GitLab Duo for JetBrains 2.7.0.
> - [Added](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/merge_requests/152) to the GitLab Neovim plugin on July 16, 2024.
> - Feature flags `advanced_context_resolver` and `code_suggestions_context` [enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161538) in GitLab 17.4.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

For better results from GitLab Duo Code Suggestions, ensure that Open Tabs Context is enabled in your IDE settings.
This feature uses the contents of the files currently open in your IDE to get more
accurate and relevant results from Code Suggestions. Like prompt engineering, these files
give GitLab Duo more information about the standards and practices in your code project.

To get the most benefit from using your open tabs as context, open the files relevant to the code
you want to create, including configuration files. When you start work in a new file,
Code Suggestions offers you suggestions in the new file.

Prerequisites:

- Requires GitLab 17.2 and later. Earlier GitLab versions that support Code Suggestions
  cannot weight the content of open tabs more heavily than other files in your project.
- Requires a [supported code language](#advanced-context-supported-languages).

1. Open the files you want to provide for context. Advanced Context uses the most recently
   opened or changed files for context. If you don’t want a file sent as additional context, close it.
1. To fine-tune your Code Generation results, add code comments to your file that explain
   what you want to build. Code Generation treats your code comments like chat. Your code comments
   update the `user_instruction`, and then improve the next results you receive.

As you work, GitLab Duo provides Code Suggestions that use your other open files
(within [truncation limits](#truncation-of-file-content))
as extra context.

To learn about the code that builds the prompt, see these files:

- **Code Generation**:
  [`ee/lib/api/code_suggestions.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/code_suggestions.rb#L76)
  in the `gitlab` repository.
- **Code Completion**:
  [`ai_gateway/code_suggestions/processing/completions.py`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/fcb3f485a8f047a86a8166aad81f93b6d82106a7/ai_gateway/code_suggestions/processing/completions.py#L273)
  in the `modelops` repository.

We'd love your feedback about the Advanced Context feature in
[issue 258](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/258).

### Advanced Context supported languages

The Advanced Context feature supports these languages:

- Code Completion: all configured languages.
- Code Generation: Go, Java, JavaScript, Kotlin, Python, Ruby, Rust, TypeScript (`.ts` and `.tsx` files), Vue, and YAML.

## Response time

Code Suggestions is powered by a generative AI model.

Your personal access token enables a secure API connection to GitLab.com or to your GitLab instance.
This API connection securely transmits a context window from your IDE/editor to the [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), a GitLab hosted service. The [gateway](../../../../development/ai_architecture.md) calls the large language model APIs, and then the generated suggestion is transmitted back to your IDE/editor.

- Code completion suggestions are usually low latency.
- For code generation:
  - Algorithms or large code blocks might take more than 10 seconds to generate.
  - Streaming of code generation responses is supported in VS Code, leading to faster average response times. Other supported IDEs offer slower response times and will return the generated code in a single block.

### Disable direct connections to the AI Gateway

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462791) in GitLab 17.2 [with a flag](../../../../administration/feature_flags.md) named `code_suggestions_direct_access`. Disabled by default.

Prerequisites:

- You must be an administrator for the GitLab self-managed instance.

To minimize latency for code completion requests, these requests are sent from the IDE directly to the AI Gateway.
For this direct connection to work, the IDE must be able to connect to `https://cloud.gitlab.com:443`. If this is not
possible (for example, because of network restrictions), you can disable direct connections for all users. If you do this,
code completion requests are sent indirectly through the GitLab self-managed instance, and might result in your requests
having higher latency.

::Tabs

:::TabTitle In 17.4 and later

In GitLab 17.4 and later, follow these instructions to disable direct connections to the gateway.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **GitLab Duo features**.
1. Under **Connection method** Choose an option:
   - To minimize latency for code completion requests, select **Direct connections**.
   - To disable direct connections for all users, select **Indirect connections through the GitLab self-managed instance**.
1. Select **Save changes**.

:::TabTitle In 17.3 and earlier

In GitLab 17.3 and earlier, follow these instructions to disable direct connections to the gateway.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **AI-powered features**.
1. Select the **Disable direct connections for code suggestions** checkbox.

::EndTabs

## Inference window context

> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.8.
> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/206) open tabs context in GitLab 17.2 [with flags](../../../../administration/feature_flags.md) named `advanced_context_resolver` and `code_suggestions_context`. Disabled by default.

Code Suggestions inferences against:

- The currently opened file
- The content before and after the cursor
- The filename and extension.
- In GitLab 17.2 and later when the `advanced_context_resolver` and `code_suggestions_context` feature flags are enabled.
  - Files opened in other tabs.
  - User instructions

For more information on possible future context expansion to improve the quality of suggestions, see [epic 11669](https://gitlab.com/groups/gitlab-org/-/epics/11669).

## Truncation of file content

Because of LLM limits and performance reasons, the content of the currently
opened file is truncated:

- For code completion: to 2048 tokens (roughly 8192 characters).
- For code generation: to 142,856 tokens (roughly 500,000 characters).

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

When using Code Suggestions, [code review best practice](../../../../development/code_review.md) still applies.

## Disable Code Suggestions

To disable Code Suggestions, disable the feature in your IDE editor extension.
For details, see the documentation for your extension.

If you'd prefer, you can
[turn off GitLab Duo for a group, project, or instance](../../../../user/gitlab_duo/turn_on_off.md).

## Feedback

Provide feedback about your Code Suggestions experience in [issue 435783](https://gitlab.com/gitlab-org/gitlab/-/issues/435783).
