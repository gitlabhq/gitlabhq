---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: index, reference
---

# Answer questions with GitLab Duo Chat **(ULTIMATE SAAS EXPERIMENT)**

> Introduced in GitLab 16.0 as an [Experiment](../policy/experiment-beta-support.md#experiment).

You can get AI generated support from GitLab Duo Chat about the following topics:

- How to use GitLab.
- Questions about an issue.
- How to use GitLab.
- Questions about an issue.
- Question about an epic.
- Questions about a code file.
- Follow-up questions to answers from the chat.

Example questions you might ask:

- `Explain the concept of a 'fork' in a concise manner.`
- `Provide step-by-step instructions on how to reset a user's password.`
- `Generate a summary for the issue identified via this link: <link to your issue>`
- `Generate a concise summary of the description of the current issue.`

The examples above all use data from either the issue or the GitLab documentation. However, you can also ask to generate code, CI/CD configurations, or to explain code. For example:

- `Write a Ruby function that prints 'Hello, World!' when called.`
- `Develop a JavaScript program that simulates a two-player Tic-Tac-Toe game. Provide both game logic and user interface, if applicable.`
- `Create a .gitlab-ci.yml configuration file for testing and building a Ruby on Rails application in a GitLab CI/CD pipeline.`
- `Provide a clear explanation of the given Ruby code: def sum(a, b) a + b end. Describe what this code does and how it works.`

In addition to the provided prompts, feel free to ask follow-up questions to delve deeper into the topic or task at hand. This helps you get more detailed and precise responses tailored to your specific needs, whether it's for further clarification, elaboration, or additional assistance.

- A follow-up to the question `Write a Ruby function that prints 'Hello, World!' when called.` could be:
  - `Could you also explain how I can call and execute this Ruby function in a typical Ruby environment, such as the command line?`

This is an experimental feature and we're continuously extending the capabilities and reliability of the chat.

## Enable GitLab Duo Chat

To use this feature, at least one group you're a member of must:

- Have the [third-party AI features setting](group/manage.md#enable-third-party-ai-features) enabled.
- Have the [experiment and beta features setting](group/manage.md#enable-experiment-and-beta-features) enabled.

## Use GitLab Duo Chat

1. In the lower-left corner, select the **Help** icon.
   The [new left sidebar must be enabled](../tutorials/left_sidebar/index.md).
1. Select **GitLab Duo Chat**. A drawer opens on the right side of your screen.
1. Enter your question in the chat input box and press **Enter** or select **Send**. It may take a few seconds for the interactive AI chat to produce an answer.
1. You can ask a follow-up question.
1. If you want to ask a new question unrelated to the previous conversation, you may receive better answers if you clear the context by typing `/reset` into the input box and selecting **Send**.

NOTE:
Only the last 50 messages are retained in the chat history. The chat history expires 3 days after last use.

## Give Feedback

Your feedback is important to us as we continually enhance your GitLab Duo Chat experience:

- **Enhance Your Experience**: Leaving feedback helps us customize the Chat for your needs and improve its performance for everyone.
- **Privacy Assurance**: Rest assured, we don't collect your prompts. Your privacy is respected, and your interactions remain private.

To give feedback about a specific response, use the feedback buttons in the response message.
Or, you can add a comment in the [feedback issue](https://gitlab.com/gitlab-org/gitlab/-/issues/415591).
