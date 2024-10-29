---
stage: Create
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: "Code Suggestions helps you write code in GitLab more efficiently by using AI to suggest code as you type."
---

# Code Suggestions

DETAILS:
**Tier:** Premium with GitLab Duo Pro, Ultimate with GitLab Duo Pro or Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced support for Google Vertex AI Codey APIs](https://gitlab.com/groups/gitlab-org/-/epics/10562) in GitLab 16.1.
> - [Removed support for GitLab native model](https://gitlab.com/groups/gitlab-org/-/epics/10752) in GitLab 16.2.
> - [Introduced support for Code Generation](https://gitlab.com/gitlab-org/gitlab/-/issues/415583) in GitLab 16.3.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/435271) in GitLab 16.7.
> - Subscription changed to require GitLab Duo Pro on February 15, 2024.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

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

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
[View a code completion vs. code generation comparison demo](https://www.youtube.com/watch?v=9dsyqMt9yg4).
  <!-- Video published on 2024-09-26 -->

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

1. When you receive a suggestion, you can do any of the following:
   - To accept a suggestion, press <kbd>Tab</kbd>.
   - To accept a partial suggestion, press either <kbd>Control</kbd>+<kbd>Right arrow</kbd> or <kbd>Command</kbd>+<kbd>Right arrow</kbd>.
   - To reject a suggestion, press <kbd>Esc</kbd>.
   - To ignore a suggestion, keep typing as you usually would.

AI is non-deterministic, so you may not get the same suggestion every time with the same input.
To generate quality code, write clear, descriptive, specific tasks.

All editor extensions from GitLab, except Neovim, add an icon to your IDE's status bar. For example, in
Visual Studio:

![The status bar in Visual Studio.](../../../../editor_extensions/img/visual_studio_status_bar_v17_4.png)

| Icon | Status | Meaning |
| :--- | :----- | :------ |
| **{tanuki-ai}** | **Ready** | You've configured and enabled GitLab Duo, and you're using a language that supports Code Suggestions. |
| **{tanuki-ai-off}** | **Not configured** | You haven't entered a personal access token, or you're using a language that Code Suggestions doesn't support. |
| ![The status icon for fetching Code Suggestions.](../../../../editor_extensions/img/code_suggestions_loading_v17_4.svg) | **Loading suggestion** | GitLab Duo is fetching Code Suggestions for you. |
| ![The status icon for a Code Suggestions error.](../../../../editor_extensions/img/code_suggestions_error_v17_4.svg) | **Error** | GitLab Duo has encountered an error. |

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

For use cases and best practices, follow the [GitLab Duo examples documentation](../../../gitlab_duo_examples.md).

## Open tabs as context

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/464767) in GitLab 17.2 [with a flag](../../../../administration/feature_flags.md) named `advanced_context_resolver`. Disabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462750) in GitLab 17.2 [with a flag](../../../../administration/feature_flags.md) named `code_suggestions_context`. Disabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/276) in GitLab Workflow for VS Code 4.20.0.
> - [Introduced](https://gitlab.com/gitlab-org/editor-extensions/gitlab-jetbrains-plugin/-/issues/462) in GitLab Duo for JetBrains 2.7.0.
> - [Added](https://gitlab.com/gitlab-org/editor-extensions/gitlab.vim/-/merge_requests/152) to the GitLab Neovim plugin on July 16, 2024.
> - Feature flags `advanced_context_resolver` and `code_suggestions_context` [enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161538) in GitLab 17.4.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.

To get more accurate and relevant results from Code Suggestions and code generation, you can use
the contents of the files open in tabs in your IDE. Similar to prompt engineering, these files
give GitLab Duo more information about the standards and practices in your code project.

### Enable open tabs as context

By default, Code Suggestions uses the open files in your IDE for context when making suggestions.

Prerequisites:

- You must have GitLab 17.2 or later. Earlier GitLab versions that support Code Suggestions
  cannot weigh the content of open tabs more heavily than other files in your project.
- GitLab Duo Code Suggestions must be enabled for your project.
- Use a [supported code language](#advanced-context-supported-languages):
  - Code completion: All configured languages.
  - Code generation: Go, Java, JavaScript, Kotlin, Python, Ruby, Rust, TypeScript (`.ts` and `.tsx` files),
    Vue, and YAML.
- For Visual Studio Code, you must have GitLab Workflow extension version 4.14.2 or later.

To confirm that open tabs are used as context:

::Tabs

:::TabTitle Visual Studio Code

1. On the top bar, go to **Code > Settings > Extensions**.
1. Search for GitLab Workflow in the list, and select the gear icon.
1. Select **Extension Settings**.
1. In your **User** settings, under **GitLab › Duo Code Suggestions: Open Tabs Context**,
   select **Use the contents of open tabs as context**.

:::TabTitle JetBrains IDEs

1. Go to your IDE's top menu bar and select **Settings**.
1. On the left sidebar, expand **Tools**, then select **GitLab Duo**.
1. Expand **GitLab Language Server**.
1. Under **Code Completion**, select **Send open tabs as context**.
1. Select **OK** or **Save**.

::EndTabs

### Use open tabs as context

Open the files you want to provide for context:

- Open tabs uses the most recently opened or changed files.
- If you do not want a file used as additional context, close that file.

When you start working in a file, GitLab Duo uses your open files
as extra context, within [truncation limits](#truncation-of-file-content).

You can adjust your code generation results by adding code comments to your file
that explain what you want to build. Code generation treats your code comments
like chat. Your code comments update the `user_instruction`, and then improve
the next results you receive.

To learn about the code that builds the prompt, see these files:

- **Code generation**:
  [`ee/lib/api/code_suggestions.rb`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/lib/api/code_suggestions.rb#L76)
  in the `gitlab` repository.
- **Code completion**:
  [`ai_gateway/code_suggestions/processing/completions.py`](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/-/blob/fcb3f485a8f047a86a8166aad81f93b6d82106a7/ai_gateway/code_suggestions/processing/completions.py#L273)
  in the `modelops` repository.

Provide feedback about this feature in
[issue 258](https://gitlab.com/gitlab-org/editor-extensions/gitlab-lsp/-/issues/258).

## Advanced Context supported languages

The Advanced Context feature supports these languages:

- Code completion: all configured languages.
- Code generation: Go, Java, JavaScript, Kotlin, Python, Ruby, Rust, TypeScript (`.ts` and `.tsx` files), Vue, and YAML.

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

## Response time

Code Suggestions is powered by a generative AI model.

- For code completion, suggestions are usually low latency and take less than one second.
- For code generation, algorithms or large code blocks might take more than five seconds to generate.

Your personal access token enables a secure API connection to GitLab.com or to your GitLab instance.
This API connection securely transmits a context window from your IDE/editor to the [GitLab AI Gateway](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist), a GitLab hosted service. The [gateway](../../../../development/ai_architecture.md) calls the large language model APIs, and then the generated suggestion is transmitted back to your IDE/editor.

### Streaming

Streaming of Code Generation responses is supported in VS Code, leading to faster average response times.
Other supported IDEs offer slower response times and will return the generated code in a single block.

### Use a self-hosted model

Instead of using the default model to manage Code Suggestions requests, you can
[deploy a self-hosted model](../../../../administration/self_hosted_models/index.md).
This maximizes security and privacy by making sure nothing is sent to an
external model.

### Direct and indirect connections

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/462791) in GitLab 17.2 [with a flag](../../../../administration/feature_flags.md) named `code_suggestions_direct_access`. Disabled by default.

By default, code completion requests are sent from the IDE directly to the AI Gateway to minimize the latency.
For this direct connection to work, the IDE must be able to connect to `https://cloud.gitlab.com:443`. If this is not
possible (for example, because of network restrictions), you can disable direct connections for all users. If you do this,
code completion requests are sent indirectly through the GitLab self-managed instance, which in turn sends the requests
to the AI Gateway. This might result in your requests having higher latency.

#### Configure direct or indirect connections

Prerequisites:

- You must be an administrator for the GitLab self-managed instance.

::Tabs

:::TabTitle In 17.4 and later

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **GitLab Duo features**.
1. Under **Connection method**, choose an option:
   - To minimize latency for code completion requests, select **Direct connections**.
   - To disable direct connections for all users, select **Indirect connections through the GitLab self-managed instance**.
1. Select **Save changes**.

:::TabTitle In 17.3 and earlier

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > General**.
1. Expand **AI-powered features**.
1. Choose an option:
   - To enable direct connections and minimize latency for code completion requests, clear the **Disable direct connections for code suggestions** checkbox.
   - To disable direct connections, select the **Disable direct connections for code suggestions** checkbox.

::EndTabs

## Disable Code Suggestions

To disable Code Suggestions, disable the feature in your IDE editor extension.
For details, see the documentation for your extension.

If you'd prefer, you can
[turn off GitLab Duo for a group, project, or instance](../../../../user/gitlab_duo/turn_on_off.md).

## Feedback

Provide feedback about your Code Suggestions experience in [issue 435783](https://gitlab.com/gitlab-org/gitlab/-/issues/435783).
