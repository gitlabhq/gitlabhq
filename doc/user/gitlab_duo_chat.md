---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Chat

DETAILS:
**Tier:** Freely available for Premium and Ultimate for a limited time for GitLab.com and self-managed. In the future, will require [GitLab Duo Pro or Enterprise](../subscriptions/subscription-add-ons.md). For GitLab Dedicated, you must have GitLab Duo Pro or Enterprise.
**Offering:** GitLab.com, Self-managed, GitLab Dedicated
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) as an [Experiment](../policy/experiment-beta-support.md#experiment) for SaaS in GitLab 16.0.
> - Changed to [Beta](../policy/experiment-beta-support.md#beta) for SaaS in GitLab 16.6.
> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/11251) as a [Beta](../policy/experiment-beta-support.md#beta) for self-managed in GitLab 16.8.
> - Changed from Ultimate to [Premium](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142808) tier in GitLab 16.9.

GitLab Duo Chat is your personal AI-powered assistant for boosting productivity.
It can assist various tasks of your daily work with the AI-generated content.

NOTE:
GitLab Duo Chat is a Beta feature. We're continuously extending the capabilities and reliability of the responses.

Here are examples of common use cases:

| Feature                                                    | Use case example                                     | Supported interfaces         | Supported deployments |
| -------------------------------------                      | ----------------                                     | --------------------------   | --------------------- |
| [Ask about GitLab](#ask-about-gitlab)                      | I want to know how to create an issue in GitLab.     | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com            |
| [Ask about a specific issue](#ask-about-a-specific-issue)  | I want to summarize this issue.                      | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Ask about a specific epic](#ask-about-a-specific-epic)    | I want to summarize this epic.                       | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Ask about code](#ask-about-code)                          | I want to understand how this code works.            | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Ask about CI/CD](#ask-about-cicd)                         | I want to create a new CI/CD pipeline configuration. | GitLab, VS Code, and Web IDE <sup>1</sup> | GitLab.com, self-managed, and GitLab Dedicated |
| [Explain code in the IDE](#explain-code-in-the-ide)        | I want to understand how this code works.            | VS Code and Web IDE <sup>1</sup>          | GitLab.com, self-managed, and GitLab Dedicated |
| [Refactor code in the IDE](#refactor-code-in-the-ide)      | I want to refactor this code.                        | VS Code and Web IDE <sup>1</sup>          | GitLab.com, self-managed, and GitLab Dedicated |
| [Write tests in the IDE](#write-tests-in-the-ide)          | I want to write a test for this code.                | VS Code and Web IDE <sup>1</sup>          | GitLab.com, self-managed, and GitLab Dedicated |

**Footnotes:**

1. GitLab Duo Chat is not available in the Web IDE on self-managed.

## Watch a demo and get tips

<div class="video-fallback">
  <a href="https://youtu.be/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_">View how to set up and use GitLab Duo Chat</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/l6vsd1HMaYA?si=etXpFbj1cBvWyj3_" frameborder="0" allowfullscreen> </iframe>
</figure>

For tips and tricks about integrating GitLab Duo Chat into your AI-powered DevSecOps workflows, read the blog post: [10 best practices for using AI-powered GitLab Duo Chat](https://about.gitlab.com/blog/2024/04/02/10-best-practices-for-using-ai-powered-gitlab-duo-chat/).

## What GitLab Duo Chat can help with

GitLab Duo Chat can help in a variety of areas.

### Ask about GitLab

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/117695) for SaaS in GitLab 16.0.

You can ask questions about how GitLab works. Things like:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

NOTE:
This feature is not currently supported in self-managed instances.
See [this epic](https://gitlab.com/groups/gitlab-org/-/epics/11600) for more information.

### Ask about a specific issue

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for SaaS in GitLab 16.0.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for self-managed in GitLab 16.8.

You can ask about a specific GitLab issue. For example:

- `Generate a summary for the issue identified via this link: <link to your issue>`
- When you are viewing an issue in GitLab, you can ask `Generate a concise summary of the current issue.`
- `How can I improve the description of <link to your issue> so that readers understand the value and problems to be solved?`

NOTE:
If the issue contains a large amount of text (more than 40,000 words), GitLab Duo Chat might not be able to consider every word. The AI model has a limit to the amount of input it can process at one time.

### Ask about a specific epic

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487) for SaaS in GitLab 16.3.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128487) for self-managed in GitLab 16.8.

You can ask about a specific GitLab epic. For example:

- `Generate a summary for the epic identified via this link: <link to your epic>`
- When you are viewing an epic in GitLab, you can ask `Generate a concise summary of the opened epic.`
- `What are the unique use cases raised by commenters in <link to your epic>?`

NOTE:
If the epic contains a large amount of text (more than 40,000 words), GitLab Duo Chat might not be able to consider every word. The AI model has a limit to the amount of input it can process at one time.

### Ask about code

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for SaaS in GitLab 16.1.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122235) for self-managed in GitLab 16.8.

You can also ask GitLab Duo Chat to generate code:

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`
- `Create a regular expression for parsing IPv4 and IPv6 addresses in Python.`
- `Generate code for parsing a syslog log file in Java. Use regular expressions when possible, and store the results in a hash map.`
- `Create a product-consumer example with threads and shared memory in C++. Use atomic locks when possible.`
- `Generate Rust code for high performance gRPC calls. Provide a source code example for a server and client.`

And you can ask GitLab Duo Chat to explain code:

- `Provide a clear explanation of the given Ruby code: def sum(a, b) a + b end. Describe what this code does and how it works.`

Alternatively, you can use the [`/explain` command](#explain-code-in-the-ide) to explain the selected code in your editor.

For more practical examples, see the [GitLab Duo examples](gitlab_duo_examples.md).

### Ask about errors

Programming languages that require compiling the source code may throw cryptic error messages. Similarly, a script or a web application could throw a stack trace. You can ask GitLab Duo Chat by prefixing the copied error message with, for example, `Please explain this error message:`. Add the specific context, like the programming language.

- `Explain this error message in Java: Int and system cannot be resolved to a type`
- `Explain when this C function would cause a segmentation fault: sqlite3_prepare_v2()`
- `Explain what would cause this error in Python: ValueError: invalid literal for int()`
- `Why is "this" undefined in VueJS? Provide common error cases, and explain how to avoid them.`
- `How to debug a Ruby on Rails stacktrace? Share common strategies and an example exception.`

For more practical examples, see the [GitLab Duo examples](gitlab_duo_examples.md).

### Ask about CI/CD

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423524) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/423524) for self-managed in GitLab 16.8.

You can ask GitLab Duo Chat to create a CI/CD configuration:

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`
- `Create a CI/CD configuration for building and linting a Python application.`
- `Create a CI/CD configuration to build and test Rust code.`
- `Create a CI/CD configuration for C++. Use gcc as compiler, and cmake as build tool.`
- `Create a CI/CD configuration for VueJS. Use npm, and add SAST security scanning.`
- `Generate a security scanning pipeline configuration, optimized for Java.`

You can also ask to explain specific job errors by copy-pasting the error message, prefixed with `Please explain this CI/CD job error message, in the context of <language>:`:

- `Please explain this CI/CD job error message in the context of a Go project: build.sh: line 14: go command not found`

Alternatively, you can use [root cause analysis in CI/CD](ai_features.md#root-cause-analysis).

For more practical examples, see the [GitLab Duo examples](gitlab_duo_examples.md).

### Explain code in the IDE

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed in GitLab 16.8.

NOTE:
This feature is available in VS Code and the Web IDE only.

`/explain` is a special command to explain the selected code in your editor.
You can also add additional instructions to be considered, for example: `/explain the performance`
See [Use GitLab Duo Chat in VS Code](#use-gitlab-duo-chat-in-vs-code) for more information.

- `/explain focus on the algorithm`
- `/explain the performance gains or losses using this code`
- `/explain the object inheritance` (classes, object-oriented)
- `/explain why a static variable is used here` (C++)
- `/explain how this function would cause a segmentation fault` (C)
- `/explain how concurrency works in this context` (Go)
- `/explain how the request reaches the client` (REST API, database)

For more practical examples, see the [GitLab Duo examples](gitlab_duo_examples.md).

### Refactor code in the IDE

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed in GitLab 16.8.

NOTE:
This feature is available in VS Code and the Web IDE only.

`/refactor` is a special command to generate a refactoring suggestion for the selected code in your editor.
You can include additional instructions to be considered. For example:

- Use a specific coding pattern, for example `/refactor with ActiveRecord` or `/refactor into a class providing static functions`.
- Use a specific library, for example `/refactor using mysql`.
- Use a specific function/algorithm, for example `/refactor into a stringstream with multiple lines` in C++.
- Refactor to a different programming language, for example `/refactor to TypeScript`.
- Focus on performance, for example `/refactor improving performance`.
- Focus on potential vulnerabilities, for example `/refactor avoiding memory leaks and exploits`.

See [Use GitLab Duo Chat in the VS Code](#use-gitlab-duo-chat-in-vs-code) for more information.

For more practical examples, see the [GitLab Duo examples](gitlab_duo_examples.md).

### Write tests in the IDE

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for SaaS in GitLab 16.7.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/429915) for self-managed in GitLab 16.8.

NOTE:
This feature is available in VS Code and the Web IDE only.

`/tests` is a special command to generate a testing suggestion for the selected code in your editor.
You can also add additional instructions to be considered, for example: `/tests using the Boost.Test framework`
See [Use GitLab Duo Chat in the VS Code](#use-gitlab-duo-chat-in-vs-code) for more information.

- Use a specific test framework, for example `/tests using the Boost.test framework` (C++) or `/tests using Jest` (JavaScript).
- Focus on extreme test cases, for example `/tests focus on extreme cases, force regression testing`.
- Focus on performance, for example `/tests focus on performance`.
- Focus on regressions and potential exploits, for example `/tests focus on regressions and potential exploits`.

For more practical examples, see the [GitLab Duo examples](gitlab_duo_examples.md).

<div class="video-fallback">
  See the video: <a href="https://www.youtube.com/watch?v=g6MS1JsRWgs">GitLab Duo Test generation</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/g6MS1JsRWgs" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2024-04-10 -->

### Ask follow up questions

You can ask follow-up questions to delve deeper into the topic or task at hand.
This helps you get more detailed and precise responses tailored to your specific needs,
whether it's for further clarification, elaboration, or additional assistance.

A follow-up to the question `Write a Ruby function that prints 'Hello, World!' when called` could be:

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

A follow-up to the question `How to start a C# project?` could be:

- `Can you also please explain how to add a .gitignore and .gitlab-ci.yml file for C#?`

For more practical examples, see the [GitLab Duo examples](gitlab_duo_examples.md).

## Supported editor extensions

To use Chat, use one of these editor extensions:

| IDE              | Extension              |
|------------------|------------------------|
| VSCode           | [VS Code GitLab Workflow extension](https://marketplace.visualstudio.com/items?itemName=GitLab.gitlab-workflow) |
| [GitLab WebIDE (VS Code in the Cloud)](project/web_ide/index.md) | No configuration required. |
| JetBrains IDEs (Experiment) | [GitLab Duo Plugin for JetBrains](https://plugins.jetbrains.com/plugin/22325-gitlab-duo) |

Visual Studio support is [under active development](https://gitlab.com/groups/gitlab-org/editor-extensions/-/epics/22). You can express interest in other IDE extension support [in this issue](https://gitlab.com/gitlab-org/editor-extensions/meta/-/issues/78).

## Enable GitLab Duo Chat

For the **GitLab Duo Chat** button to be displayed in the GitLab UI,
you must enable GitLab Duo Chat.

### For GitLab.com

To enable GitLab Duo Chat on GitLab.com:

- At least one group that you're a member of must
  have the [Experiment and Beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.
- You must belong to a group that has a Premium or Ultimate subscription.

You can ask questions only about resources that belong to groups where the experiment and beta features setting is enabled.

### For self-managed and GitLab Dedicated

Prerequisites:

- You must have GitLab version 16.8 or later.
- You must have a Premium or Ultimate subscription that is [synchronized with GitLab](https://about.gitlab.com/pricing/licensing-faq/cloud-licensing/).
- Your firewalls and HTTP proxy servers must allow outbound connections
  to `cloud.gitlab.com`. To use an HTTP proxy, both
  `gitLab _workhorse` and `gitLab_rails` have the necessary
  [web proxy environment variables](https://docs.gitlab.com/omnibus/settings/environment-variables.html) set.
- All of the users in your instance have the latest version of their IDE extension.
- You must be an administrator.

For GitLab Dedicated, you must have [GitLab Duo Pro or Enterprise](../subscriptions/subscription-add-ons.md).

To enable GitLab Duo Chat for your self-managed GitLab instance:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **AI-powered features** and select **Enable Experiment and Beta AI-powered features**.
1. Select **Save changes**.
1. To make sure GitLab Duo Chat works immediately, you must
   [manually synchronize your subscription](#manually-synchronize-your-subscription).

NOTE:
Usage of GitLab Duo Chat is governed by the [GitLab Testing Agreement](https://handbook.gitlab.com/handbook/legal/testing-agreement/).
Learn about [data usage when using GitLab Duo Chat](ai_features.md#data-usage).

#### Manually synchronize your subscription

You must [manually synchronize your subscription](../subscriptions/self_managed/index.md#manually-synchronize-your-subscription-details) if either:

- You have just purchased a subscription for the Premium or Ultimate tier and have upgraded to GitLab 16.8.
- You already have a subscription for the Premium or Ultimate tier and have upgraded to GitLab 16.8.

Without the manual synchronization, it might take up to 24 hours to activate GitLab Duo Chat on your instance.

## Use GitLab Duo Chat in the GitLab UI

1. In the upper-right corner, select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Enter your question in the chat input box and press **Enter** or select **Send**. It may take a few seconds for the interactive AI chat to produce an answer.
1. Optional. Ask a follow-up question.

To ask a new question unrelated to the previous conversation, you might receive better answers
if you clear the context by typing `/reset` and selecting **Send**.

NOTE:
Only the last 50 messages are retained in the chat history. The chat history expires 3 days after last use.

### Delete all conversations

To delete all previous conversations:

- In the text box, type `/clear` and select **Send**.

## Use GitLab Duo Chat in the Web IDE

DETAILS:
**Tier:** Premium, Ultimate
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
**Tier:** Premium, Ultimate
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

1. Go to **Settings > Extensions > GitLab Workflow (GitLab VS Code Extension)**.
1. Clear the **Enable GitLab Duo Chat assistant** checkbox.

## Give feedback

Your feedback is important to us as we continually enhance your GitLab Duo Chat experience.
Leaving feedback helps us customize the Chat for your needs and improve its performance for everyone.

To give feedback about a specific response, use the feedback buttons in the response message.
Or, you can add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).

## Troubleshooting

When working with GitLab Duo Chat, you might encounter the following issues.

### The **GitLab Duo Chat** button is not displayed

If the button is not visible in the upper-right of the UI,
ensure GitLab Duo Chat [is enabled](#enable-gitlab-duo-chat).

The **GitLab Duo Chat** button is not displayed on personal projects,
as well as groups and projects with GitLab Duo features disabled.

After you enable GitLab Duo Chat, it might take a few minutes for the
button to appear.

### `This feature is only allowed in groups or projects that enable this feature`

This error occurs when you ask about resources that do not have
GitLab Duo Chat [enabled](#enable-gitlab-duo-chat).

If any of the settings are not enabled, information about resources
(like issues, epics, and merge requests) in the group or project
cannot be processed by GitLab Duo Chat.

### `I am sorry, I am unable to find what you are looking for`

This error occurs when you ask GitLab Duo Chat about resources you don't have access to,
or about resources that do not exist.

Try again, asking about resources you have access to.

### Reponses are unexpected

If you have are on GitLab.com and have access to GitLab Duo Chat responses you did not expect,
you might be part of a group that has the **Use Experiment and Beta features** setting enabled.
Review the list of your groups and verify which ones you have access to.

GitLab.com administrators can verify your access by running this snippet in the Rails console:

```ruby
u = User.find_by_username($USERNAME)
u.member_namespaces.namespace_settings_with_ai_features_enabled.with_ai_supported_plan(:ai_chat)
```

You can ask specific questions about group resources (like "summarize this issue") when this feature is enabled.
