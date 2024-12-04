---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Chat

DETAILS:
**Tier:** Premium with GitLab Duo Pro, Ultimate with GitLab Duo Pro or Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) as an [experiment](../../policy/development_stages_support.md#experiment) for SaaS in GitLab 16.0.
> - Changed to [beta](../../policy/development_stages_support.md#beta) for SaaS in GitLab 16.6.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11251) as a [beta](../../policy/development_stages_support.md#beta) for self-managed in GitLab 16.8.
> - Changed from Ultimate to [Premium](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142808) tier in GitLab 16.9 while in [beta](../../policy/development_stages_support.md#beta).
> - Changed to [generally available](../../policy/development_stages_support.md#generally-available-ga) in GitLab 16.11.
> - Changed to require GitLab Duo add-on in GitLab 17.6 and later.

GitLab Duo Chat is your personal AI-powered assistant for boosting productivity.
It can assist various tasks of your daily work with the AI-generated content.

## Supported editor extensions

You can use GitLab Duo Chat in:

- The GitLab UI
- [The GitLab Web IDE (VS Code in the cloud)](../project/web_ide/index.md)
- VS Code, with the [GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- JetBrains IDEs, with the [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)
- Visual Studio for Windows, with the [GitLab Extension for Visual Studio](https://marketplace.visualstudio.com/items?itemName=GitLab.GitLabExtensionForVisualStudio)

NOTE:
If you have self-managed GitLab: GitLab Duo requires GitLab 17.2 and later for the best user experience and results. Earlier versions may continue to work, however the experience may be degraded.

## The context Chat is aware of

GitLab Duo Chat is sometimes aware of the context you're working in.
Other times, you must be more specific with your request.

In the GitLab UI, GitLab Duo Chat knows about these areas:

| Area          | How to ask Chat                                                                                                  |
|---------------|------------------------------------------------------------------------------------------------------------------|
| Epics         | From the epic, ask about `this epic`, `this`, or the URL. From any UI area, ask about the URL.                   |
| Issues        | From the issue, ask about `this issue`, `this`, or the URL. From any UI area, ask about the URL.                 |
| Code files    | From the single file, ask about `this code` or `this file`. From any UI area, ask about the URL.                 |
| Merge requests | From the merge request, ask about `this merge request`, `this`, or the URL. For more information, see [Ask about a specific merge request](examples.md#ask-about-a-specific-merge-request). |
| Commits        | From the commit, ask about `this commit` or `this`. From any UI area, ask about the URL.                        |
| Pipeline jobs  | From the pipeline job, ask about `this pipeline job` or `this`. From any UI area, ask about the URL.            |

In the IDEs, GitLab Duo Chat knows about these areas:

| Area    | How to ask Chat  |
|---------|------------------|
| Selected lines in the editor | With the lines selected, ask about `this code` or `this file`. Chat is not aware of the file; you must select the lines you want to ask about. |
| Epics   | Ask about the URL. |
| Issues  | Ask about the URL. |

In addition, in the IDEs, when you use any of the slash commands,
like `/explain`, `/refactor`, `/fix`, or `/tests,` Duo Chat has access to the
code you selected.

Duo Chat always has access to:

- GitLab documentation.
- General programming and coding knowledge.

We are continuously working to expand contextual awareness of Chat to include more types of content.

## Use GitLab Duo Chat in the GitLab UI

1. In the upper-right corner, select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Enter your question in the chat input box and press **Enter** or select **Send**. It may take a few seconds for the interactive AI chat to produce an answer.
1. Optional. Ask a follow-up question.

To ask a new question unrelated to the previous conversation, you might receive better answers
if you clear the context by typing `/reset` or `/clear` and selecting **Send**.

NOTE:
Only the last 50 messages are retained in the chat history. The chat history expires 3 days after last use.

## Use GitLab Duo Chat in the Web IDE

> - Introduced in GitLab 16.6 as an [experiment](../../policy/development_stages_support.md#experiment).
> - Changed to generally available in GitLab 16.11.

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

> - Introduced in GitLab 16.6 as an [experiment](../../policy/development_stages_support.md#experiment).
> - Changed to generally available in GitLab 16.11.

Prerequisites:

- You've [installed the VS Code extension](../../editor_extensions/visual_studio_code/index.md#install-the-extension).
- You've [authenticated the extension with GitLab](../../editor_extensions/visual_studio_code/index.md#authenticate-with-gitlab).
- [Confirm that GitLab Duo is on](../../editor_extensions/visual_studio_code/index.md#confirm-that-gitlab-duo-is-on).

To use GitLab Duo Chat in GitLab Workflow extension for VS Code:

1. In VS Code, open a file. The file does not need to be a file in a Git repository.
1. Open Chat by using one of the following methods:
   - On the left sidebar, select **GitLab Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code** or **Generate Tests**.
   - Use the keyboard shortcut: <kbd>ALT</kbd>+<kbd>d</kbd> (on Windows and Linux) or <kbd>Option</kbd>+<kbd>d</kbd> (on Mac).
1. In the message box, enter your question and press **Enter** or select **Send**.

If you have selected code in the editor, this selection is sent along with your question to the AI. This way you can ask questions about this code selection. For instance, `Could you simplify this?`.

### In the editor window

> - Introduced as [generally available](https://gitlab.com/groups/gitlab-org/-/epics/15218) in the GitLab Workflow extension for VS Code 5.15.0.

To open GitLab Duo Chat in the editor window, use any of these methods:

- From a keyboard shortcut, by pressing:
  - MacOS: <kbd>Option</kbd> + <kbd>c</kbd>
  - Windows and Linux: <kbd>ALT</kbd> + <kbd>c</kbd>
- In the currently open file in your IDE, by selecting some code.
- Right-clicking, then selecting **GitLab Duo Chat > Open Quick Chat**.

After Quick Chat opens:

1. In the message box, enter your question. The available commands are shown while you enter text:
   - Enter `/` to display all available commands.
   - Enter `/re` to display `/refactor`.
1. To send your question, select **Send**, or press <kbd>Command</kbd> + <kbd>Enter</kbd>.
1. To exit chat, either select the chat icon in the gutter, or press **Escape** while focused on the chat.

## Use GitLab Duo Chat in Visual Studio for Windows

To use GitLab Duo Chat in the GitLab extension for Visual Studio:

1. Install and set up the extension for Visual Studio:
   1. In Visual Studio, download and install the [GitLab extension for Visual Studio](../../editor_extensions/visual_studio/index.md).
   1. Configure the [GitLab extension for Visual Studio](../../editor_extensions/visual_studio/index.md).
1. In Visual Studio, open a file. The file does not need to be a file in a Git repository.
1. Open Chat by using one of the following methods:
   - In the top menu bar, click on **Extensions** and then select **Open Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code** or **Generate Tests**.
1. In the message box, enter your question and press **Enter** or select **Send**.

If you have selected code in the editor, this selection is sent along with your question to the AI. This way you can ask questions about this code selection. For instance, `Could you refactor this?`.

## Use GitLab Duo Chat in JetBrains IDEs

> - Introduced as generally available in GitLab 16.11.

To use GitLab Duo Chat in the GitLab Duo plugin for JetBrains IDEs:

1. Install and set up the GitLab Duo plugin for JetBrains IDEs:
   1. In the JetBrains marketplace, download and install the [GitLab Duo plugin](../../editor_extensions/jetbrains_ide/index.md#install-the-extension).
   1. Configure the [GitLab Duo plugin](../../editor_extensions/jetbrains_ide/index.md#configure-the-extension).
1. In a JetBrains IDE, open a project.
1. Open GitLab Duo Chat in either a chat window or an editor window:

### In a chat window

To open GitLab Duo Chat in a chat window, use any of these methods:

- On the right tool window bar, by selecting **GitLab Duo Chat**.
- From a keyboard shortcut, by pressing:
  - MacOS: <kbd>Option</kbd> + <kbd>d</kbd>
  - Windows and Linux: <kbd>ALT</kbd> + <kbd>d</kbd>
- In the file that you have open in the editor:
  1. Optional. Select some code.
  1. Right-click and select **GitLab Duo Chat**.
  1. Select **Open Chat Window**.
  1. Select **Explain Code**, **Generate Tests**, or **Refactor Code**.
- Adding keyboard or mouse shortcuts for each action under **Keymap** in the **Settings**.

After GitLab Duo Chat opens:

1. In the message box, enter your question. The available commands are shown while you enter text:
   - Enter `/` to display all available commands.
   - Enter `/re` to display `/refactor` and `/reset`.
1. To send your question, press **Enter** or select **Send**.
1. Use the buttons within code blocks in the responses to interact with them.

### In GitLab Duo Quick Chat in the editor view

> - Introduced as generally available in the [GitLab Duo plugin for JetBrains 3.0.0](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/80) and [GitLab Workflow extension for VS Code 5.14.0](https://gitlab.com/groups/gitlab-org/-/epics/15218).

To open GitLab Duo Chat Quick Chat in the editor window, use any of these methods:

- From a keyboard shortcut, by pressing:
  - MacOS: <kbd>Option</kbd> + <kbd>c</kbd>
  - Windows and Linux: <kbd>ALT</kbd> + <kbd>c</kbd>
- In the currently open file in your IDE, by selecting some code,
  then, in the floating toolbar, selecting **GitLab Duo Quick Chat** (**{tanuki-ai}**).
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

## Watch a demo and get tips

<div class="video-fallback">
  <a href="https://youtu.be/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_">View how to set up and use GitLab Duo Chat</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2023-11-10 -->

For tips and tricks about integrating GitLab Duo Chat into your AI-powered DevSecOps workflows,
read the blog post:
[10 best practices for using AI-powered GitLab Duo Chat](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/).

[View examples of how to use GitLab Duo Chat](../gitlab_duo_chat/examples.md).

## Give feedback

Your feedback is important to us as we continually enhance your GitLab Duo Chat experience.
Leaving feedback helps us customize the Chat for your needs and improve its performance for everyone.

To give feedback about a specific response, use the feedback buttons in the response message.
Or, you can add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).
