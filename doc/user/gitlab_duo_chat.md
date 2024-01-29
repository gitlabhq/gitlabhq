---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Chat

DETAILS:
**Tier:** Ultimate
**Offering:** SaaS, self-managed
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) as an [Experiment](../policy/experiment-beta-support.md#experiment) for SaaS in GitLab 16.0.
> - Changed to [Beta](../policy/experiment-beta-support.md#beta) for SaaS in GitLab 16.6.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11251) as a [Beta](../policy/experiment-beta-support.md#beta) for self-managed in GitLab 16.8.

GitLab Duo Chat is your personal AI-powered assistant for boosting productivity.
It can assist various tasks of your daily work with the AI-generated content.
Here are the examples of use cases:

| Feature                                                    | Use case example                                     | Supported interfaces         | Supported deployments |
| -------------------------------------                      | ----------------                                     | --------------------------   | --------------------- |
| [Ask about GitLab](#ask-about-gitlab)                      | I want to know how to create an issue in GitLab.     | GitLab, VS Code, and Web IDE <sup>1</sup>   | GitLab.com            |
| [Ask about a specific issue](#ask-about-a-specific-issue)  | I want to summarize this issue.                      | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Ask about a specific epic](#ask-about-a-specific-epic)    | I want to summarize this epic.                       | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Ask about code](#ask-about-code)                          | I want to understand how this code works.            | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Ask about CI/CD](#ask-about-cicd)                         | I want to create a new CI/CD pipeline configuration. | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Explain code in the IDE](#explain-code-in-the-ide)        | I want to understand how this code works.            | VS Code and Web IDE <sup>1</sup>          | GitLab.com, self-managed, and GitLab Dedicated |
| [Refactor code in the IDE](#explain-code-in-the-ide)       | I want to write a test for this code.                | VS Code and Web IDE <sup>1</sup>          | GitLab.com, self-managed, and GitLab Dedicated |
| [Write tests in the IDE](#write-tests-in-the-ide)          | I want to refactor this code.                        | VS Code and Web IDE <sup>1</sup>         | GitLab.com, self-managed, and GitLab Dedicated |

<html>
<small>Footnotes:
  <ol>
    <li>GitLab Duo Chat is not available in Web IDE on self-managed</li>
  </ol>
</small>
</html>

NOTE:
This is a Beta feature. We're continuously extending the capabilities and reliability of the responses.

## Watch a demo

<div class="video-fallback">
  <a href="https://youtu.be/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_">View how to setup and use GitLab Duo Chat</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_" frameborder="0" allowfullscreen> </iframe>
</figure>

## What GitLab Duo Chat can help with

GitLab Duo Chat can help in a variety of areas.

### Ask about GitLab

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) for SaaS in GitLab 16.0.

You can ask questions about how GitLab works. Things like:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

NOTE:
This feature is not currently supported in self-managed instances.
See [this epic](https://gitlab.com/groups/gitlab-org/-/epics/11600) for more infomation.

### Ask about a specific issue

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for SaaS in GitLab 16.0.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for self-managed in GitLab 16.8.

You can ask about a specific GitLab issue. For example:

- `Generate a summary for the issue identified via this link: <link to your issue>`
- When you are viewing an issue in GitLab, you can ask `Generate a concise summary of the current issue.`
- `How can I improve the description of <link to your issue> so that readers understand the value and problems to be solved?`

### Ask about a specific epic

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487) for SaaS in GitLab 16.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487) for self-managed in GitLab 16.8.

You can ask about a specific GitLab epic. For example:

- `Generate a summary for the epic identified via this link: <link to your epic>`
- `Generate a concise summary of the opened epic.`
- `What are the unique use cases raised by commenters in <link to your epic>?`

### Ask about code

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for SaaS in GitLab 16.1.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for self-managed in GitLab 16.8.

You can also ask GitLab Duo Chat to generate code:

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`

And you can ask GitLab Duo Chat to explain code:

- `Provide a clear explanation of the given Ruby code: def sum(a, b) a + b end. Describe what this code does and how it works.`

### Ask about CI/CD

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423524) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423524) for self-managed in GitLab 16.8.

You can ask GitLab Duo Chat to create a CI/CD configuration:

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`

### Explain code in the IDE

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed in GitLab 16.8.

NOTE:
This feature is available in VS Code and the Web IDE only.

`/explain` is a special command to explain the selected code in your editor.
You can also add additional instructions to be considered, for example: `/explain the performance`
See [Use GitLab Duo Chat in VS Code](#use-gitlab-duo-chat-in-vs-code) for more information.

### Refactor code in the IDE

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed in GitLab 16.8.

NOTE:
This feature is available in VS Code and the Web IDE only.

`/refactor` is a special command to generate a refactoring suggestion for the selected code in your editor.
You can also add additional instructions to be considered, for example: `/refactor with ActiveRecord`
See [Use GitLab Duo Chat in the VS Code](#use-gitlab-duo-chat-in-vs-code) for more information.

### Write tests in the IDE

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed in GitLab 16.8.

NOTE:
This feature is available in VS Code and the Web IDE only.

`/tests` is a special command to generate a testing suggestion for the selected code in your editor.
You can also add additional instructions to be considered, for example: `/tests using the Boost.Test framework`
See [Use GitLab Duo Chat in the VS Code](#use-gitlab-duo-chat-in-vs-code) for more information.

### Ask follow up questions

You can ask follow-up questions to delve deeper into the topic or task at hand.
This helps you get more detailed and precise responses tailored to your specific needs,
whether it's for further clarification, elaboration, or additional assistance.

A follow-up to the question `Write a Ruby function that prints 'Hello, World!' when called` could be:

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

## Enable GitLab Duo Chat

### For SaaS users

To use this feature, at least one group you're a member of must
have the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.

### For self-managed users

NOTE:
Usage of GitLab Duo Chat is governed by the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using GitLab Duo Chat](ai_features.md#data-usage).

Prerequisites:

- You are using GitLab version 16.8 or later.
- The Ultimate license is activated in your GitLab instance by using [cloud Licensing](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/).
- All of the users in your instance have the latest version of their IDE extension.
- You are an administrator.

To enable GitLab Duo Chat for your self-managed GitLab instance:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **AI-powered features** and select **Enable Experiment and Beta AI-powered features**.
1. Select **Save changes**.
1. To make sure GitLab Duo Chat works immediately, you must
   [manually synchronize your subscription](#manually-synchronize-your-subscription).

#### Manually synchronize your subscription

You must [manually synchronize your subscription](../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details) if either:

- You have just purchased a subscription for the Ultimate tier and have upgraded to GitLab 16.8.
- You already have a subscription for the Ultimate tier and have upgraded to GitLab 16.8.

Without the manual synchronization, it might take up to 24 hours to activate GitLab Duo Chat on your instance.

## Use GitLab Duo Chat in the GitLab UI

1. In the lower-left corner, select the **Help** icon.
   The [new left sidebar must be enabled](../tutorials/left_sidebar/index.md).
1. Select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Enter your question in the chat input box and press **Enter** or select **Send**. It may take a few seconds for the interactive AI chat to produce an answer.
1. You can ask a follow-up question.
1. If you want to ask a new question unrelated to the previous conversation, you may receive better answers if you clear the context by typing `/reset` into the input box and selecting **Send**.

NOTE:
Only the last 50 messages are retained in the chat history. The chat history expires 3 days after last use.

### Delete all conversations

To delete all previous conversations:

1. In the text box, type `/clean` and select **Send**.

## Use GitLab Duo Chat in the Web IDE

DETAILS:
**Tier:** Ultimate
**Status:** Experiment

> - Introduced in GitLab 16.6 as an [Experiment](../policy/experiment-beta-support.md#experiment)

To use GitLab Duo Chat in the Web IDE on GitLab:

1. Open the Web IDE:
   1. On the left sidebar, select **Search or go to** and find your project.
   1. Select a file. Then in the upper right, select **Edit > Open in Web IDE**.
1. Then open Chat by using one of the following methods:
   - On the left sidebar, select **GitLab Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code** or **Generate Tests**.

   - Use the keyboard shortcut: <kbd>ALT</kbd>+<kbd>d</kbd> (on Windows and Linux) or <kbd>Option</kbd>+<kbd>d</kbd> (on Mac)

1. In the message box, enter your question and press **Enter** or select **Send**.

If you have selected code in the editor, this selection is sent along with your question to the AI. This way you can ask questions about this code selection. For instance, `Could you simplify this?`.

NOTE:
GitLab Duo Chat is not available in the Web IDE on self-managed.

## Use GitLab Duo Chat in VS Code

DETAILS:
**Tier:** Ultimate
**Status:** Experiment

> - Introduced in GitLab 16.6 as an [Experiment](../policy/experiment-beta-support.md#experiment).

To use GitLab Duo Chat in GitLab Workflow extension for VS Code:

1. Install and set up the Workflow extension for VS Code:
   1. In VS Code, download and Install the [GitLab Workflow extension for VS Code](../editor_extensions/visual_studio_code/index.md#download-the-extension).
   1. Configure the [GitLab Workflow extension](../editor_extensions/visual_studio_code/index.md#configure-the-extension).
1. In VS Code, open a file. The file does not need to be a file in a Git repository.
1. Open Chat by using one of the following methods:
   - On the left sidebar, select **GitLab Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code** or **Generate Tests**.
   - Use the keyboard shortcut: <kbd>ALT</kbd>+<kbd>d</kbd> (on Windows and Linux) or <kbd>Option</kbd>+<kbd>d</kbd> (on Mac)
1. In the message box, enter your question and press **Enter** or select **Send**.

If you have selected code in the editor, this selection is sent along with your question to the AI. This way you can ask questions about this code selection. For instance, `Could you simplify this?`.

### Perform standard task in the IDE from the context menu or by using slash commands

Get code explained, code refactored or get tests generated for code. To do so:

1. Select code in your editor in VS Code or in the Web IDE.
1. Type one the following slash commands into the chat field: [`/explain`](#explain-code-in-the-ide), [`/refactor`](#refactor-code-in-the-ide) or [`/tests`](#write-tests-in-the-ide). Alternatively, use the context menu to perform these tasks.

When you use one of the slash commands you can also add additional instructions to be considered, for example: `/tests using the Boost.Test framework`

### Disable Chat in VS Code

To disable GitLab Duo Chat in VS Code:

1. Go to **Settings > Extensions > GitLab Workflow (GitLab VSCode Extension)**.
1. Clear the **Enable GitLab Duo Chat assistant** checkbox.

## Give feedback

Your feedback is important to us as we continually enhance your GitLab Duo Chat experience.
Leaving feedback helps us customize the Chat for your needs and improve its performance for everyone.

To give feedback about a specific response, use the feedback buttons in the response message.
Or, you can add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).
