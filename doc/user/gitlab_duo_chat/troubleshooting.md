---
stage: AI-powered
group: Duo Chat
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo Chat troubleshooting
---

When working with GitLab Duo Chat, you might encounter the following issues.

## The **GitLab Duo Chat** button is not displayed

If the button is not visible in the upper-right of the UI,
ensure GitLab Duo Chat [is enabled](turn_on_off.md).

The **GitLab Duo Chat** button is not displayed on personal projects,
as well as
[groups and projects with GitLab Duo features disabled](turn_on_off.md).

After you enable GitLab Duo Chat, it might take a few minutes for the
button to appear.

If this does not work, you can also check the following troubleshooting documentation:

- [GitLab Duo Code Suggestions](../project/repository/code_suggestions/troubleshooting.md)
- [VS Code](../../editor_extensions/visual_studio_code/troubleshooting.md)
- [Microsoft Visual Studio](../../editor_extensions/visual_studio/visual_studio_troubleshooting.md)
- [JetBrains IDEs](../../editor_extensions/jetbrains_ide/jetbrains_troubleshooting.md)
- [Neovim](../../editor_extensions/neovim/neovim_troubleshooting.md)

## `Error M2000`

You might get an error that states
`I'm sorry, I couldn't find any documentation to answer your question. Error code: M2000`.

This error occurs when Chat is unable to find relevant documentation to answer your question. This can happen if the search query does not match any available documents or if there is an issue with the document search functionality.

Try again or refer to the [GitLab Duo Chat best practices documentation](best_practices.md) to refine your question.

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

Ensure your [GitLab Duo subscription tier](https://about.gitlab.com/gitlab-duo/#pricing) includes the selected tool.

## `Error M3006`

You might get an error that states
`I'm sorry, you don't have the GitLab Duo subscription required to use Duo Chat. Please contact your administrator. Error code: M3006`.

This error occurs when GitLab Duo Chat is not included in your GitLab Duo subscription.

Ensure your [GitLab Duo subscription tier](https://about.gitlab.com/gitlab-duo/#pricing) includes GitLab Duo Chat.

## `Error M4000`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M4000`.

This error occurs when an unexpected issue arises during the processing of a slash command request. Try your request again. If the problem persists, ensure that the syntax of your command is correct.

For more information about slash commands, refer to the documentation:

- [/tests](../gitlab_duo_chat/examples.md#write-tests-in-the-ide)
- [/refactor](../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)
- [/fix](../gitlab_duo_chat/examples.md#fix-code-in-the-ide)
- [/explain](../gitlab_duo_chat/examples.md#explain-selected-code)

## `Error M4001`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M4001`.

This error occurs when there is a problem finding the information needed to complete your request. Try your request again.

## `Error M4002`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M4002`.

This error occurs when there is a problem answering [questions related to CI/CD](../gitlab_duo_chat/examples.md#ask-about-cicd). Try your request again.

## `Error M4003`

You might get an error that states
`This command is used for explaining vulnerabilities and can only be invoked from a vulnerability detail page.` or
`Vulnerability Explanation currently only supports vulnerabilities reported by SAST. Error code: M4003`.

This error occurs when there is a problem when using [`Explain Vulnerability`](../gitlab_duo_chat/examples.md#explain-a-vulnerability) feature.

## `Error M4004`

You might get an error that states
`This resource has no comments to summarize`.

This error occurs when there is a problem when using `Summarize Discussion` feature.

## `Error M4005`

You might get an error that states
`There is no job log to troubleshoot.` or `This command is used for troubleshooting jobs and can only be invoked from a failed job log page.`.

This error occurs when there is a problem when using [`Troubleshoot job`](../gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis) feature.

## `Error M5000`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: M5000`.

This error occurs when there is an issue while processing the content related to an item (like issue, epic, and merge request). Try your request again.

## `Error A1000`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1000`.

This error occurs when there is a timeout during processing. Try your request again.

## `Error A1001`

You might get an error that states
`I'm sorry, I can't generate a response. Please try again. Error code: A1001`.

This error means there was a problem encountered by the AI service that processed your request.

Some possible reasons:

- A client-side error caused by a bug in the GitLab code.
- A server-side error caused by a bug in the Anthropic code.
- An HTTP request that didn't reach the AI gateway.

[An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/479465) to more clearly specify the reason for the error.

To resolve the issue, try your request again.

If the error persists, use the `/clear` command to reset the chat.
If the problem continues, report the issue to the GitLab Support team.

## `Error A1002`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1002`.

This error occurs when no events are returned from AI gateway or GitLab failed to parse the events. Try your request again.

## `Error A1003`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1003`.

This error occurs when streaming response from AI gateway failed. Try your request again.

## `Error A1004`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A1004`.

This error occurs when an error occurred in the AI gateway process. Try your request again.

## `Error A1005`

You might get an error that states
`I'm sorry, you've entered too many prompts. Please run /clear or /reset before asking the next question. Error code: A1005`.

This error occurs when the length of prompts exceeds the max token limit of the LLM. Start a new conversation with the `/new` command and try your request again.

## `Error A1006`

You might get an error that states
`I'm sorry, Duo Chat agent reached the limit before finding an answer for your question. Please try a different prompt or clear your conversation history with /clear. Error code: A1006`.

This error occurs when ReAct agent failed to find a solution for your query. Try a different prompt or clear your conversation history with `/clear`.

## `Error A9999`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try again. Error code: A9999`.

This error occurs when an unknown error occurs in ReAct agent. Try your request again.

## `Error A6000`

You might get an error that states
`I'm sorry, I couldn't respond in time. Please try a more specific request or enter /clear to start a new chat. Error code: A6000`.

This is a fallback error that occurs when there is a problem with GitLab Duo Chat.
Try a more specific request, enter `/clear` to start a new chat, or leave feedback to help us improve.

## `Error G3001`

You might get an error that states
`I'm sorry, but answering this question requires a different Duo subscription. Please contact your administrator.`.

This error occurs when GitLab Duo Chat is not available in your subscription.
Try a different request and contact your administrator.

## Header mismatch issue

You might get an error that states `I'm sorry, I can't generate a response. Please try again`, without a specific error code.

Check the Sidekiq logs to see if you find the following error:`Header mismatch 'X-Gitlab-Instance-Id'`.

If you see this error, then to resolve it, contact the GitLab support team and ask them to send you a new activation code for the license.

For more information, see [issue 103](https://gitlab.com/gitlab-com/enablement-sub-department/section-enable-request-for-help/-/issues/103).

## Check the health of the Cloud Connector

We have created a script that verifies the status of various components related to the Cloud Connector, such as:

- Access data
- Tokens
- Licenses
- Host connectivity
- Feature accessibility

You can run this script in debug mode for more detailed output and to generate a report file.

1. SSH into your single node instance and download the script:

   ```shell
   wget https://gitlab.com/gitlab-org/gitlab/-/snippets/3734617/raw/main/health_check.rb
   ```

1. Use Rails Runner to execute the script.

   Ensure that you use the full path to the script.

   ```ruby
   Usage: gitlab-rails runner full_path/to/health_check.rb
          --debug                     Enable debug mode
          --output-file <file_path>   Write a report to a specified file
          --username <username>       Provide a username to test seat assignments
          --skip [CHECK]              Skip specific checks (options: access_data, token, license, host, features, end_to_end)
   ```
