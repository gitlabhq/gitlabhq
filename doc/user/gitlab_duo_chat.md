---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Answer questions with GitLab Duo Chat **(ULTIMATE SAAS BETA)**

> Introduced in GitLab 16.6 as a [Beta](../policy/experiment-beta-support.md#beta).

You can get AI-generated support from GitLab Duo Chat about:

- How to use GitLab.
- The contents of an issue or issue.
- The contents of a code or CI/CD configuration file.

You can also use GitLab Duo Chat to create code and CI/CD files.

When you get an answer, you can ask follow-up questions to learn more.

This is a Beta feature. We're continuously extending the capabilities and reliability of the responses.

## Ask about GitLab

You can ask questions about how GitLab works. Things like:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`

## Ask about your work

You can ask about GitLab issues and epics. For example:

- `Generate a summary for the issue identified via this link: <link to your issue>`
- `Generate a concise summary of the current issue.`

## Ask about code

You can also ask GitLab Duo Chat to generate code:

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`

And you can ask GitLab Duo Chat to explain code:

- `Provide a clear explanation of the given Ruby code: def sum(a, b) a + b end. Describe what this code does and how it works.`

## Ask about CI/CD

You can ask GitLab Duo Chat to create a CI/CD configuration:

- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`

## Ask follow up questions

You can ask follow-up questions to delve deeper into the topic or task at hand.
This helps you get more detailed and precise responses tailored to your specific needs,
whether it's for further clarification, elaboration, or additional assistance.

A follow-up to the question `Write a Ruby function that prints 'Hello, World!' when called` could be:

- `Can you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

## Enable GitLab Duo Chat

To use this feature, at least one group you're a member of must
have the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.

## Use GitLab Duo Chat

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

## Use GitLab Duo Chat in the Web IDE and VS Code **(ULTIMATE SAAS EXPERIMENT)**

> Introduced in GitLab 16.6 as an [EXPERIMENT](../policy/experiment-beta-support.md#experiment).

### Web IDE

To use GitLab Duo Chat in the Web IDE on GitLab.com:

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

### GitLab Workflow extension for VS Code

To use GitLab Duo Chat in VS Code:

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

### Disable Chat in Web IDE and VS Code

To disable GitLab Duo Chat in the Web IDE and VS Code:

1. Go to **Settings > Extensions > GitLab Workflow (GitLab VSCode Extension)**.
1. Clear the **Enable GitLab Duo Chat assistant** checkbox.

## Give feedback

Your feedback is important to us as we continually enhance your GitLab Duo Chat experience:

- **Enhance Your Experience**: Leaving feedback helps us customize the Chat for your needs and improve its performance for everyone.

To give feedback about a specific response, use the feedback buttons in the response message.
Or, you can add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/430124).
