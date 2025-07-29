---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, Pro, or Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- LLMs: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4), Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet), Anthropic [Claude 3.5 Sonnet V2](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet-v2), Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet), Anthropic [Claude 3.5 Haiku](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-haiku), and [Vertex AI Search](https://cloud.google.com/enterprise-search). The LLM depends on the question asked.
- LLM for Amazon Q: Amazon Q Developer

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) as an [experiment](../../policy/development_stages_support.md#experiment) for SaaS in GitLab 16.0.
- Changed to [beta](../../policy/development_stages_support.md#beta) for SaaS in GitLab 16.6.
- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11251) as a [beta](../../policy/development_stages_support.md#beta) for GitLab Self-Managed in GitLab 16.8.
- Changed from Ultimate to [Premium](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142808) tier in GitLab 16.9 while in [beta](../../policy/development_stages_support.md#beta).
- [Generally available](../../policy/development_stages_support.md#generally-available) in GitLab 16.11.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.

{{< /history >}}

GitLab Duo Chat is an AI-native assistant that accelerates development with
contextual, conversational AI. Chat:

- Explains code and suggests improvements directly in your development environment.
- Analyzes code, merge requests, issues, and other GitLab artifacts.
- Generates code, tests, and documentation based on your requirements and codebase.
- Integrates directly in the GitLab UI, Web IDE, VS Code, JetBrains IDEs, and Visual Studio.
- Can include information from your repositories and projects to deliver targeted improvements.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=ZQBAuf-CTAY)
<!-- Video published on 2024-04-18 -->

## Supported editor extensions

You can use GitLab Duo Chat in:

- The GitLab UI
- [The GitLab Web IDE (VS Code in the cloud)](../project/web_ide/_index.md)
- VS Code, with the [GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- JetBrains IDEs, with the [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)
- Eclipse, with the [GitLab for Eclipse extension](https://marketplace.eclipse.org/content/gitlab-eclipse)
- Visual Studio for Windows, with the [GitLab Extension for Visual Studio](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio)

{{< alert type="note" >}}

If you have GitLab Self-Managed: GitLab Duo requires GitLab 17.2 and later for the best user experience and results. Earlier versions may continue to work, however the experience may be degraded.

{{< /alert >}}

## Use GitLab Duo Chat in the GitLab UI

1. In the upper-right corner, select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Enter your question in the chat text box and press **Enter** or select **Send**.
   - You can provide additional [context](../gitlab_duo/context.md#gitlab-duo-chat) for your chat.
   - It may take a few seconds for the interactive AI chat to produce an answer.
1. Optional. Ask a follow-up question.

The 25 most recent messages are retained in the chat history.

To ask a new question unrelated to the previous conversation, you might receive better answers
if you clear the context by typing `/reset` or `/clear` and selecting **Send**.

{{< alert type="note" >}}

The **GitLab Duo Chat** button is **not available** on:

- The **Your work** pages, like the [To-Do List](../todos.md).
- Your [**User settings**](../profile/_index.md) page.
- The **Help** menu.

{{< /alert >}}

### Have multiple conversations with Chat

{{< details >}}

- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/16108) in GitLab 17.10 [with a flag](../../administration/feature_flags/_index.md) named `duo_chat_multi_thread`. Disabled by default.
- [Enabled on GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/187443) in GitLab 17.11.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190042) in GitLab 18.1. Feature flag `duo_chat_multi_thread` removed.

{{< /history >}}

In GitLab 17.10 and later, you can have multiple simultaneous conversations with Chat.

1. In the upper-right corner, select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Enter your question in the chat text box and press **Enter** or select **Send**.
1. To create a new conversation with Chat, you can either:
   - In the top-left corner of the Chat drawer, select **New Chat**.
   - In the text box, type `/new` and press <kbd>Enter</kbd> or select **Send**.
   A new Chat drawer replaces the previous one.

   You can have an unlimited number of simultaneous conversations with Chat.

1. To view all of your conversations, in the top-left corner of the Chat drawer, select **Chat History**.

   Conversations created before the multiple conversations feature was enabled are not visible in the Chat history.

1. To switch between conversations, in your Chat history, select the appropriate conversation.

   Every conversation persists an unlimited number of messages. However, only the last 25 messages are sent to the LLM to fit the content in the LLM's context window.

#### Delete a conversation

To delete a conversation:

1. In the top-left corner of the Chat drawer, select **Chat History**.
1. In the Chat history, select **Delete conversation**.

> By default, individual conversations expire and are automatically deleted after 30 days of inactivity.
> However, administrators can [change this expiration period](#configure-chat-conversation-expiration).

## Use GitLab Duo Chat in the Web IDE

{{< history >}}

- Introduced in GitLab 16.6 as an [experiment](../../policy/development_stages_support.md#experiment).
- Changed to generally available in GitLab 16.11.

{{< /history >}}

To use GitLab Duo Chat in the Web IDE on GitLab:

1. Open the Web IDE:
   1. In the GitLab UI, on the left sidebar, select **Search or go to** and find your project.
   1. Select a file. Then in the upper right, select **Edit > Open in Web IDE**.
1. Then open Chat by using one of the following methods:
   - On the left sidebar, select **GitLab Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code**, **Generate Tests**, or **Refactor**.
   - Use the keyboard shortcut: <kbd>ALT</kbd>+<kbd>d</kbd> (on Windows and Linux) or <kbd>Option</kbd>+<kbd>d</kbd> (on Mac)
1. In the message box, enter your question and press **Enter** or select **Send**.

If you have selected code in the editor, this selection is sent along with your question to the AI. This way you can ask questions about this code selection. For instance, `Could you simplify this?`.

## Use GitLab Duo Chat in VS Code

{{< history >}}

- Introduced in GitLab 16.6 as an [experiment](../../policy/development_stages_support.md#experiment).
- Changed to generally available in GitLab 16.11.
- Status [added](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/issues/1712) in the GitLab Workflow extension for VS Code 5.29.0.

{{< /history >}}

Prerequisites:

- You've [installed and configured the VS Code extension](../../editor_extensions/visual_studio_code/setup.md).

To use GitLab Duo Chat in GitLab Workflow extension for VS Code:

1. In VS Code, open a file. The file does not need to be a file in a Git repository.
1. On the left sidebar, select **GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
1. In the message box, enter your question and press **Enter** or select **Send**.
1. In the chat pane, on the top right corner, select **Show Status** to show information
   in the Command Palette.

### Select code and use Duo Chat

You can interact with Duo Chat while you're working with a subset of code.

1. In VS Code, open a file. The file does not need to be a file in a Git repository.
1. In the file, select some code.
1. Right-click and select **GitLab Duo Chat**.
1. Select an option, or **Open Quick Chat** and ask a question, like `Can you simplify this code?` and press <kbd>Enter</kbd>.

### Close Duo Chat

To close Duo Chat:

- For Duo Chat on the left sidebar, select **GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
- For the quick chat window that's embedded in your file, in the upper-right corner,
  select **Collapse** ({{< icon name="chevron-lg-up" >}}).

### In the editor window

{{< history >}}

- Introduced as [generally available](https://gitlab.com/groups/gitlab-org/-/epics/15218) in the GitLab Workflow extension for VS Code 5.15.0.
- Insert Snippet [added](https://gitlab.com/gitlab-org/gitlab-vscode-extension/-/merge_requests/2150) in the GitLab Workflow extension for VS Code 5.25.0.

{{< /history >}}

To open GitLab Duo Chat in the editor window, use any of these methods:

- From a keyboard shortcut, by pressing:
  - MacOS: <kbd>Option</kbd> + <kbd>c</kbd>
  - Windows and Linux: <kbd>ALT</kbd> + <kbd>c</kbd>
- Right-clicking in the currently open file in your IDE, then selecting **GitLab Duo Chat > Open Quick Chat**.
  Optionally, select some code to provide additional context.
- Opening the [Command Palette](https://code.visualstudio.com/docs/getstarted/userinterface#_command-palette),
  then selecting **GitLab Duo Chat: Open Quick Chat**.

After Quick Chat opens:

1. In the message box, enter your question. The available commands are shown while you enter text:
   - Enter `/` to display all available commands.
   - Enter `/re` to display `/refactor`.
1. To send your question, select **Send**, or press <kbd>Command</kbd> + <kbd>Enter</kbd>.
1. Use the **Copy Snippet** and **Insert Snippet** links above code blocks in the responses to interact with them.
1. To exit chat, either select the chat icon in the gutter, or press **Escape** while focused on the chat.

## Use GitLab Duo Chat in Visual Studio for Windows

Prerequisites:

- You've [installed and configured the GitLab extension for Visual Studio](../../editor_extensions/visual_studio/setup.md).

To use GitLab Duo Chat in the GitLab extension for Visual Studio:

1. In Visual Studio, open a file. The file does not need to be a file in a Git repository.
1. Open Chat by using one of the following methods:
   - In the top menu bar, click on **Extensions** and then select **Open Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code** or **Generate Tests**.
1. In the message box, enter your question and press **Enter** or select **Send**.

If you have selected code in the editor, this selection is sent along with your question to the AI. This way you can ask questions about this code selection. For instance, `Could you refactor this?`.

## Use GitLab Duo Chat in JetBrains IDEs

{{< history >}}

- Introduced as generally available in GitLab 16.11.

{{< /history >}}

Prerequisites:

- You've [installed and configured the GitLab plugin for JetBrains IDEs](../../editor_extensions/jetbrains_ide/setup.md).

To use GitLab Duo Chat in the GitLab plugin for JetBrains IDEs:

1. In a JetBrains IDE, open a project.
1. Open GitLab Duo Chat in either a chat window or an editor window.

### In a chat window

To open GitLab Duo Chat in a chat window, use any of these methods:

- On the right tool window bar, by selecting **GitLab Duo Chat**.
- From a keyboard shortcut, by pressing:
  - MacOS: <kbd>Option</kbd> + <kbd>d</kbd>
  - Windows and Linux: <kbd>ALT</kbd> + <kbd>d</kbd>
- From an open editor file:
  1. Right-click and select **GitLab Duo Chat**.
  1. Select **Open Chat Window**.
- With selected code:
  1. In an editor, select code to include with your command.
  1. Right-click and select **GitLab Duo Chat**.
  1. Select **Explain Code**, **Fix Code**, **Generate Tests**, or **Refactor Code**.
- From a highlighted code issue:
  1. Right-click and select **Show Context Actions**.
  1. Select **Fix with Duo**.
- With a keyboard or mouse shortcut for a GitLab Duo action, which you can set in **Settings > Keymap**.

After GitLab Duo Chat opens:

1. In the message box, enter your question. The available commands are shown while you enter text:
   - Enter `/` to display all available commands.
   - Enter `/re` to display `/refactor` and `/reset`.
1. To send your question, press **Enter** or select **Send**.
1. Use the buttons within code blocks in the responses to interact with them.

### In GitLab Duo Quick Chat in the editor view

{{< history >}}

- Introduced as generally available in the [GitLab Duo plugin for JetBrains 3.0.0](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/80) and [GitLab Workflow extension for VS Code 5.14.0](https://gitlab.com/groups/gitlab-org/-/epics/15218).

{{< /history >}}

To open GitLab Duo Chat Quick Chat in the editor window, use any of these methods:

- From a keyboard shortcut, by pressing:
  - MacOS: <kbd>Option</kbd> + <kbd>c</kbd>
  - Windows and Linux: <kbd>ALT</kbd> + <kbd>c</kbd>
- In an open file in your IDE, by selecting some code,
  then, in the floating toolbar, selecting **GitLab Duo Quick Chat** ({{< icon name="tanuki-ai" >}}).
- Right-clicking, then selecting **GitLab Duo Chat > Open Quick Chat**.

After Quick Chat opens:

1. In the message box, enter your question. The available commands are shown while you enter text:
   - Enter `/` to display all available commands.
   - Enter `/re` to display `/refactor` and `/reset`.
1. To send your question, press **Enter**.
1. Use the buttons around code blocks in the responses to interact with them.
1. To exit chat, either select **Escape to close**, or press **Escape** while focused on the chat.

<div class="video-fallback">
  <a href="https://youtu.be/5JbAM5g2VbQ">View how to use GitLab Duo Quick Chat</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube.com/embed/5JbAM5g2VbQ?si=pm7bTRDCR5we_1IX" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-10-15 -->

## Use GitLab Duo Chat in Eclipse

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/editor-extensions/gitlab-eclipse-plugin/-/issues/163) from experiment to beta in GitLab 17.11.

{{< /history >}}

Prerequisites:

- You've [installed and configured the GitLab for Eclipse plugin](../../editor_extensions/eclipse/setup.md).

To use GitLab Duo Chat in the GitLab for Eclipse plugin:

1. Open a project in Eclipse.
1. To open the chat window, select **GitLab Duo Chat** ({{< icon name="duo-chat" >}}), or use the keyboard shortcut:
   - Windows and Linux: <kbd>ALT</kbd> + <kbd>d</kbd> on Windows and Linux
   - MacOS: <kbd>Option</kbd> + <kbd>d</kbd>
1. In the message box, enter your question and press **Enter** or select **Send**.

## Watch a demo and get tips

<div class="video-fallback">
  <a href="https://youtu.be/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_">View how to set up and use GitLab Duo Chat</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2023-11-10 -->

For tips and tricks about integrating GitLab Duo Chat into your AI-native DevSecOps workflows,
read the blog post:
[10 best practices for using AI-powered GitLab Duo Chat](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/).

[View examples of how to use GitLab Duo Chat](examples.md).

## Configure Chat conversation expiration

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/161997) in GitLab 17.11.

{{< /history >}}

You can configure how long conversations persist before they expire and are automatically deleted.

Prerequisites:

- You must be an administrator.

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **GitLab Duo**.
1. In the lower-right corner, select **Change configuration**.
1. In the **GitLab Duo Chat conversation expiration** section, select either of the following options:

   - **Expire conversation based on time conversation was last updated**.
   - **Expire conversation based on time conversation was created**.
1. Select **Save changes**.

## Available language models

Different language models can be the source for GitLab Duo Chat.

- On GitLab.com or GitLab Self-Managed, the default GitLab AI vendor models and
  cloud-based AI gateway that is hosted by GitLab.
- On GitLab Self-Managed, in GitLab 17.9 and later, [GitLab Duo Self-Hosted with a supported self-hosted model](../../administration/gitlab_duo_self_hosted/_index.md). Self-hosted models maximize
  security and privacy by making sure nothing is sent to an external model.

## Input and output length

For each Chat conversation, input and output length is limited:

- Input is limited to 200,000 tokens (roughly 680,000 characters). The input tokens
  include:
  - All the [context that Chat is aware of](../gitlab_duo/context.md#gitlab-duo-chat).
  - All the previous questions and answers in that conversation.
- Output is limited to 8,192 tokens (roughly 28,600 characters).

## Give feedback

Your feedback is important to us as we continually enhance your GitLab Duo Chat experience.
Leaving feedback helps us customize the Chat for your needs and improve its performance for everyone.

To give feedback about a specific response, use the feedback buttons in the response message.
Or, you can add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).
