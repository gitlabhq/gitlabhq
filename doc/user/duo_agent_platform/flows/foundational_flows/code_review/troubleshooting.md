---
stage: AI Coding
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting Code Review Flow
---

When working with Code Review Flow, you might encounter the following issues.

## `Error DCR4000`

You might get an error that states
`Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`.

This error occurs when either [foundational flows](../_index.md) or Code Review Flow are turned off.

Contact your administrator and ask them to turn on Code Review Flow for your top-level group.

## `Error DCR4001`

You might get an error that states
`Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`.

This error occurs when Code Review Flow is turned on, but the service account for the top-level
group does not exist or is not ready.

Ask your administrator to [verify that the service account exists](../../../troubleshooting.md#foundational-flow-service-account-not-created) and to follow the steps to resolve
any issues.

## `Error DCR4002`

You might get an error that states
`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`.

This error occurs when you have used all of your allocated GitLab Credits for the current billing period.

Contact your administrator to purchase additional credits or wait for your credits to reset at the start of the next billing period.

## `Error DCR4003`

You might get an error that states
`<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`.

This error occurs because Code Review Flow runs on a CI/CD pipeline, and you don't have permission to create pipelines in this project.

Contact your administrator and ask them to give you the required [permissions to execute pipelines](../../../../permissions.md).

## `Error DCR4004`

You might get an error that states
`<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`.

This error occurs when GitLab Duo cannot identify a default GitLab Duo namespace for the user that started the review.

Set a default GitLab Duo namespace in your [preferences](../../../../profile/preferences.md#set-a-default-gitlab-duo-namespace), then request a review again.

## `Error DCR4005`

You might get an error that states
`Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`.

Code Review Flow requires authentication tokens to connect to the GitLab AI Gateway and the GitLab API. This error occurs when those tokens cannot be generated, usually due to an incorrect GitLab Duo setup or a transient infrastructure issue.

For self-managed instances, ask your administrator to verify the [GitLab Duo configuration](../../../../../administration/gitlab_duo/configure/_index.md).

## `Error DCR4006`

You might get an error that states
`Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`.

This error occurs when the service account cannot be added as a member of the project. This can happen when a group membership lock is enabled or the service account does not have the required access.

Contact your administrator and ask them to verify that the service account can be added to the project as a developer.

## `Error DCR4007`

You might get an error that states
`Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`.

This error occurs when the flow is disabled or the required configuration is missing for the project.

Contact your administrator and ask them to verify that
[the flow is enabled](../_index.md#turn-foundational-flows-on-or-off) for the project.

## `Error DCR4008`

You might get an error that states
`Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`.

This error occurs when Code Review Flow cannot create or configure the CI/CD pipeline to run the review because of runner availability issues or internal configuration problems.

Try to restart the review. If the error persists, contact your administrator.

## `Error DCR4009`

You might get an error that states
`Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`.

This error occurs when Code Review Flow is unable to retrieve the source branch for the merge request.

Try to restart the review.

## `Error DCR5000`

You might get an error that states
`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`.

This error occurs when GitLab Duo Agent Platform is unable to start Code Review Flow due to an internal error.

Try to restart the review. If the error persists, contact your administrator.

## `Error DCR5001`

You might get an error that states
`Code Review Flow completed the review but could not post the review comments. Please request a new review to try again. Error code: DCR5001`.

This error occurs when Code Review Flow completes the review but, after several attempts, cannot post the review comments. This is often due to transient infrastructure issues.

Request a new review. If the error persists, contact your administrator.

## Missing context in large merge request reviews

Code Review Flow might miss context when a merge request contains many large changed files.

This can occur when the pre-scan results exceed the
[file and context limits](_index.md#file-and-context-limits) and the data is truncated before the review.

To improve the review:

- Split the merge request into smaller merge requests.
- [Exclude context](../../../context.md#exclude-context-from-gitlab-duo) for files that are not
  relevant to the review.
- Ask a group Owner or instance administrator to select a different model for
  [GitLab.com](../../../model_selection.md#select-a-model-for-a-feature)
  or [GitLab Self-Managed and GitLab Dedicated](../../../../../administration/gitlab_duo/model_selection.md#select-a-model-for-code-review-flow).

## Configuration diagnostic script

If you cannot identify the cause of a Code Review Flow issue from the documented error codes, you
can run a diagnostic script to check your GitLab Duo configuration.

The script checks the full configuration chain required for Code Review Flow, including checks that
apply to all GitLab Duo Agent Platform features.

For more information, see [run the configuration diagnostic script](../../../troubleshooting.md#run-the-configuration-diagnostic-script).
