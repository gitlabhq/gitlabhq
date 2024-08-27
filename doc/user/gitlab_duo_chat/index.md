---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Chat

DETAILS:
**Tier: GitLab.com and Self-managed:** For a limited time, Premium or Ultimate. In the future, Premium with GitLab Duo Pro or Ultimate with [GitLab Duo Pro or Enterprise](../../subscriptions/subscription-add-ons.md). **GitLab Dedicated:** GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) as an [experiment](../../policy/experiment-beta-support.md#experiment) for SaaS in GitLab 16.0.
> - Changed to [beta](../../policy/experiment-beta-support.md#beta) for SaaS in GitLab 16.6.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11251) as a [beta](../../policy/experiment-beta-support.md#beta) for self-managed in GitLab 16.8.
> - Changed from Ultimate to [Premium](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142808) tier in GitLab 16.9 while in [beta](../../policy/experiment-beta-support.md#beta).
> - Changed to [generally available](../../policy/experiment-beta-support.md#generally-available-ga) in GitLab 16.11.
> - Freely available for Ultimate and Premium users for a limited time.

GitLab Duo Chat is your personal AI-powered assistant for boosting productivity.
It can assist various tasks of your daily work with the AI-generated content.

> For a limited time, the following users have free access to GitLab Duo Chat:
>
> - GitLab.com users who are members of at least one group with a Premium or Ultimate subscription.
> - GitLab self-managed users with a Premium or Ultimate subscription.
>
> Eventually a subscription add-on will be required for continued access to GitLab Duo Chat.
> Learn more about [Duo Pro and Duo Enterprise pricing](https://about.gitlab.com/gitlab-duo/#pricing).

For GitLab Dedicated, you must have GitLab Duo Pro or Enterprise.

## Supported editor extensions

You can use GitLab Duo Chat in:

- The GitLab UI
- [The GitLab Web IDE (VS Code in the cloud)](../project/web_ide/index.md)
- VS Code, with the [GitLab Workflow extension for VS Code](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow)
- JetBrains IDEs, with the [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo)

Visual Studio support is
[under active development](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/22).
You can express interest in other IDE extension support
[in this issue](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78).

## The context Chat is aware of

GitLab Duo Chat is sometimes aware of the context you're working in.
Other times, you must be more specific with your request.

In the GitLab UI, GitLab Duo Chat knows about these areas:

| Area          | How to ask Chat                                                                                                  |
|---------------|------------------------------------------------------------------------------------------------------------------|
| Epics         | From the epic, ask about `this epic`, `this`, or the URL. From any UI area, ask about the URL.                   |
| Issues        | From the issue, ask about `this issue`, `this`, or the URL. From any UI area, ask about the URL.                 |
| Code files    | From the single file, ask about `this code` or `this file`. From any UI area, ask about the URL.                 |

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

> - Introduced in GitLab 16.6 as an [experiment](../../policy/experiment-beta-support.md#experiment).
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

NOTE:
GitLab Duo Chat is not available in the Web IDE on self-managed.

## Use GitLab Duo Chat in VS Code

> - Introduced in GitLab 16.6 as an [experiment](../../policy/experiment-beta-support.md#experiment).
> - Changed to generally available in GitLab 16.11.

To use GitLab Duo Chat in GitLab Workflow extension for VS Code:

1. Install and set up the Workflow extension for VS Code:
   1. In VS Code, download and install the [GitLab Workflow extension for VS Code](../../editor_extensions/visual_studio_code/index.md).
   1. Configure the [GitLab Workflow extension](../../editor_extensions/visual_studio_code/index.md).
1. In VS Code, open a file. The file does not need to be a file in a Git repository.
1. Open Chat by using one of the following methods:
   - On the left sidebar, select **GitLab Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code** or **Generate Tests**.
   - Use the keyboard shortcut: <kbd>ALT</kbd>+<kbd>d</kbd> (on Windows and Linux) or <kbd>Option</kbd>+<kbd>d</kbd> (on Mac)
1. In the message box, enter your question and press **Enter** or select **Send**.

If you have selected code in the editor, this selection is sent along with your question to the AI. This way you can ask questions about this code selection. For instance, `Could you simplify this?`.

## Use GitLab Duo Chat in JetBrains IDEs

> - Introduced as generally available in GitLab 16.11.

To use GitLab Duo Chat in the GitLab Duo plugin for JetBrains IDEs:

1. Install and set up the GitLab Duo plugin for JetBrains IDEs:
   1. In the JetBrains marketplace, download and install the [GitLab Duo plugin](../../editor_extensions/jetbrains_ide/index.md#download-the-extension).
   1. Configure the [GitLab Duo plugin](../../editor_extensions/jetbrains_ide/index.md#configure-the-extension).
1. In a JetBrains IDE, open a project.
1. Open Chat by using one of the following methods:
   - On the right tool window bar, select **GitLab Duo Chat**.
   - Use a keyboard shortcut: <kbd>ALT</kbd> + <kbd>d</kbd> on Windows and Linux, or
     <kbd>Option</kbd> + <kbd>d</kbd> on macOS.
   - In the file that you have open in the editor:
     1. Optional. Select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Open Chat Window**.
     1. Select **Explain Code**, **Generate Tests**, or **Refactor Code**.
   - Add keyboard or mouse shortcuts for each action under **Keymap** in the **Settings**.
1. In the message box, enter your question and press **Enter** or select **Send**.

## Watch a demo and get tips

<div class="video-fallback">
  <a href="https://youtu.be/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_">View how to set up and use GitLab Duo Chat</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_" frameborder="0" allowfullscreen> </iframe>
</figure>

For tips and tricks about integrating GitLab Duo Chat into your AI-powered DevSecOps workflows,
read the blog post:
[10 best practices for using AI-powered GitLab Duo Chat](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/).

[View examples of how to use GitLab Duo Chat](../gitlab_duo_chat/examples.md).

## Give feedback

Your feedback is important to us as we continually enhance your GitLab Duo Chat experience.
Leaving feedback helps us customize the Chat for your needs and improve its performance for everyone.

To give feedback about a specific response, use the feedback buttons in the response message.
Or, you can add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).
