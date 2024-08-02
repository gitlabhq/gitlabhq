---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo Chat troubleshooting

When working with GitLab Duo Chat, you might encounter the following issues.

## The **GitLab Duo Chat** button is not displayed

If the button is not visible in the upper-right of the UI,
ensure GitLab Duo Chat [is enabled](turn_on_off.md).

The **GitLab Duo Chat** button is not displayed on personal projects,
as well as
[groups and projects with GitLab Duo features disabled](turn_on_off.md).

After you enable GitLab Duo Chat, it might take a few minutes for the
button to appear.

## `Error M2000`

You might get an error that states
`I'm sorry, I couldn't find any documentation to answer your question. Error code: M2000`.

This error occurs when Duo Chat is unable to find relevant documentation to answer your question. This can happen if the search query does not match any available documents or if there is an issue with the document search functionality.

Please try again or refer to the [Duo Chat best practices documentation](best_practices.md) to refine your question.

## `Error M3002`

You might get an error that states
`I am sorry, I cannot access the information you are asking about. A group or project owner has turned off Duo features in this group or project. Error code: M3002`.

This error occurs when you ask about items that belong to projects or groups with
GitLab Duo [turned off](turn_on_off.md).

If GitLab Duo is not turned on, information about items
(like issues, epics, and merge requests) in the group or project cannot be processed by GitLab Duo Chat.

## `Error M3003`

You might get an error that states
`I'm sorry, I can't generate a response. You might want to try again. You could also be getting this error because the items you're asking about either don't exist, you don't have access to them, or your session has expired. Error code: M3003`.

This error occurs when:

- You ask GitLab Duo Chat about items (like issues, epics, and merge requests) you don't have access to, or about items that don't exist.
- Your session has expired.

Try again, asking about items you have access to. If you continue to experience issues, it might be due to an expired session. To continue using GitLab Duo Chat, sign in again. For more information, see [Control GitLab Duo availability](../gitlab_duo/turn_on_off.md).

## `Error M3004`

You might get an error that states
`I'm sorry, I can't generate a response. You do not have access to GitLab Duo Chat. Error code: M3004`.

This error occurs when you try to access GitLab Duo Chat but do not have the access needed.

Ensure you have [access to use GitLab Duo Chat](../gitlab_duo/turn_on_off.md).

## `Error M3005`

You might get an error that states
`I'm sorry, this question is not supported in your Duo Pro subscription. You might consider upgrading to Duo Enterprise. Error code: M3005`.

This error occurs when you try to access a tool of GitLab Duo Chat that is not bundled in your GitLab Duo subscription tier.

Ensure your [GitLab Duo subscription tier](https://about.gitlab.com/gitlab-duo/) includes the selected tool.

## `Error M4000`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M4000`.

This error occurs when an unexpected issue arises during the processing of a slash command request. Please try your request again. If the problem persists, ensure that the syntax of your command is correct.

For more information about slash commands, refer to the documentation:

- [/tests](../gitlab_duo_chat/examples.md#write-tests-in-the-ide)
- [/refactor](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)
- [/fix](../gitlab_duo_chat/examples.md#fix-code-in-the-ide)
- [/explain](../gitlab_duo_chat/examples.md#explain-code-in-the-ide)

## `Error M4001`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M4001`.

This error occurs when there is a problem finding the information needed to complete your request. Please try your request again.

## `Error M4002`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M4002`.

This error occurs when there is a problem answering [questions related to CI/CD](../gitlab_duo_chat/examples.md#ask-about-cicd). Please try your request again.

## `Error M5000`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M5000`.

This error occurs when there is an issue while processing the content related to an item (like issue, epic, and merge request). Please try your request again.

## `Error A1000`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`.

This error occurs when there is a timeout during processing. Please try your request again.

## `Error A1001`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: A1001`.

This error occurs when there is a connection error during processing. Please try your request again.

## `Error A6000`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try a more specific request or enter /clear to start a new chat. Error code: A6000`.

This is a fallback error that occurs when there is a problem with GitLab Duo Chat.
Please try a more specific request, enter `/clear` to start a new chat, or leave feedback to help us improve.
