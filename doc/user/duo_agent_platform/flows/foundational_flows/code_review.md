---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Code Review Flow
---

{{< details >}}

- Tier: [Free](../../../../subscriptions/gitlab_credits.md#for-the-free-tier), Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude Sonnet 4 Vertex](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Available on [GitLab Duo with self-hosted models](../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../../../policy/development_stages_support.md) in GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645) [with a flag](../../../../administration/feature_flags/_index.md) named `duo_code_review_on_agent_platform`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8. Feature flag `duo_code_review_on_agent_platform` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209).
- Available on the Free tier on GitLab.com with GitLab Credits in GitLab 18.10.

{{< /history >}}

> [!note]
> Depending on your add-on, GitLab runs one of two code review features:
>
> - Code Review Flow: the agentic version, part of GitLab Duo Agent Platform.
> - GitLab Duo Code Review: the non-agentic version, available only for users with the GitLab Duo Enterprise add-on.
>
> This page describes the agentic version.
> Learn how [the two features compare](../../../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code).

The Code Review Flow helps you streamline code reviews with agentic AI.

This flow:

- Analyzes code changes.
- Provides enhanced contextual understanding of repository structure and cross-file dependencies.
- Delivers detailed review comments with actionable feedback.
- Supports custom review instructions tailored to your project.

This flow is available in the GitLab UI only.

## Use the flow

Prerequisites:

- Ensure you meet the [Agent Platform prerequisites](../../_index.md#prerequisites).
- Ensure **Allow foundational flows** and **Code Review** are [turned on](_index.md#turn-foundational-flows-on-or-off) for the top-level group.
- Ensure you have the Developer, Maintainer, or Owner [role](../../../permissions.md) for the project.
- Ensure [a runner](../execution.md#configure-runners) is available and configured for the project. 
- If you belong to multiple GitLab Duo namespaces, ensure you have [a default GitLab Duo namespace](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace) set in your preferences.

To use the Code Review Flow on a merge request:

1. In the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. Use one of these methods to request a review:
   - Assign `@GitLabDuo` as a reviewer.
   - In a comment box, enter the quick action `/assign_reviewer @GitLabDuo`.

After you request a review, Code Review Flow starts a [session](../../sessions/_index.md) that you
can monitor until the review is complete.

## Interact with GitLab Duo in reviews

In addition to assigning GitLab Duo as a reviewer, you can interact with GitLab Duo
by:

- Replying to its review comments to ask for clarification or alternative approaches.
- Mentioning `@GitLabDuo` in any discussion thread to ask follow-up questions.

Interactions with GitLab Duo can help to improve the suggestions and feedback as you work to improve
your merge request.

Feedback provided to GitLab Duo does not influence later reviews of other merge requests.
There is a feature request to add this functionality, see [issue 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116).

## Contextual awareness

Code Review Flow runs in two stages:

1. Pre-scan: The flow inspects the merge request diffs and uses them to identify related
   context to fetch from the project repository. The pre-scan typically includes directory
   listings and the contents of related files, such as tests and dependencies referenced by the
   changes. The exact context fetched depends on the diff analysis.
1. Review: The flow runs the review with the following data in the large language model. The review stage cannot fetch additional context on demand.

   - Results from the pre-scan step.
   - Merge request title.
   - Merge request description.
   - Merge request diffs.
   - Original versions of the files.
   - Filenames.
   - Custom review instructions.

To specify content to exclude, see
[exclude context from GitLab Duo](../../context.md#exclude-context-from-gitlab-duo).

### File and context limits

Code Review Flow applies two limits to keep the prompt within a workable size:

- For files longer than 10,000 lines, only the diff is sent to the model. The full file contents are not included.
- The total context that the pre-scan gathers is capped at approximately 1 MiB. When the cap is
  exceeded, the context is truncated to approximately 800 KiB before the review stage runs.

These limits apply to the data the flow gathers and are separate from the
[selected model's](../../model_selection.md) context window.

For very large merge requests, the review might miss context that was truncated. To reduce the
risk:

- Split the merge request into smaller merge requests.
- [Exclude context](../../context.md#exclude-context-from-gitlab-duo) for files that are not
  relevant to the review.

## Custom code review instructions

Customize the behavior of Code Review Flow with an `mr-review-instructions.yaml` file.

You can guide GitLab Duo with repository-specific review instructions:

- Focus on specific code quality aspects (such as security, performance, and maintainability).
- Enforce coding standards and best practices unique to your project.
- Target specific file patterns with tailored review criteria.
- Provide more detailed explanations for certain types of changes.

Code Review Flow does not reference `AGENTS.md` and `SKILL.md` files.

To configure custom instructions, see [customize review instructions for GitLab Duo](../../customize/review_instructions.md).

## Automatic reviews from GitLab Duo for a project

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) to a UI setting in GitLab 18.0.

{{< /history >}}

Automatic reviews from GitLab Duo ensure that all merge requests in your project receive an initial review.
After a merge request is created, GitLab Duo reviews it unless:

- It's marked as draft. For GitLab Duo to review the merge request, mark it ready.
- It contains no changes. For GitLab Duo to review the merge request, add changes to it.

Prerequisites:

- You must have at least the [Maintainer role](../../../permissions.md) in a project.

To enable `@GitLabDuo` to automatically review merge requests:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Merge requests**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

For information on how credit usage is attributed for automatic reviews, see
[determine which code review feature runs](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs).

## Automatic reviews from GitLab Duo for groups and applications

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/554070) in GitLab 18.4 as a [beta](../../../../policy/development_stages_support.md#beta) [with a flag](../../../../administration/feature_flags/_index.md) named `cascading_auto_duo_code_review_settings`. Disabled by default.
- Feature flag `cascading_auto_duo_code_review_settings` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213240) in GitLab 18.7.

{{< /history >}}

Use group or application settings to enable automatic reviews for multiple projects.

Prerequisites:

- To turn on automatic reviews for groups, have the Owner role for the group.
- To turn on automatic reviews for all projects, be an administrator.

To enable automatic reviews for groups:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Settings** > **General**.
1. Expand the **Merge requests** section.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

To enable automatic reviews for all projects:

1. In the upper-right corner, select **Admin**.
1. In the left sidebar, select **Settings** > **General**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

Settings cascade from application to group to project. More specific settings override broader ones.

For information on how credit usage is attributed for automatic reviews, see
[determine which code review feature runs](../../../project/merge_requests/duo_in_merge_requests.md#determine-which-review-feature-runs).

## Troubleshooting

### `Error DCR4000`

You might get an error that states
`Code Review Flow is not enabled. Contact your group administrator to enable the foundational flow in the top-level group. Error code: DCR4000`.

This error occurs when either [foundational flows](_index.md) or Code Review Flow are turned off.

Contact your administrator and ask them to turn on Code Review Flow for your top-level group.

### `Error DCR4001`

You might get an error that states
`Code Review Flow is enabled but the service account needs to be verified. Contact your administrator. Error code: DCR4001`.

This error occurs when Code Review Flow is turned on, but the service account for the top-level group
is not ready or is still being created.

Wait a few minutes for the service account to activate, then try again. If the error persists,
contact your administrator and ask them to verify that a service account has been created
in the top-level group with the Developer role.

### `Error DCR4002`

You might get an error that states
`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`.

This error occurs when you have used all of your allocated GitLab Credits for the current billing period.

Contact your administrator to purchase additional credits or wait for your credits to reset at the start of the next billing period.

### `Error DCR4003`

You might get an error that states
`<User>, you don't have permission to create a pipeline for Code Review Flow in this project. Contact your administrator to update your permissions. Error code: DCR4003`.

This error occurs because Code Review Flow runs on a CI/CD pipeline, and you don't have permission to create pipelines in this project.

Contact your administrator and ask them to give you the required [permissions to execute pipelines](../../../permissions.md).

### `Error DCR4004`

You might get an error that states
`<User>, you need to set a default GitLab Duo namespace to use Code Review Flow in this project. Please set a default GitLab Duo namespace in your preferences. Error code: DCR4004`.

This error occurs when GitLab Duo cannot identify a default GitLab Duo namespace for the user that started the review.

Set a default GitLab Duo namespace in your [preferences](../../../profile/preferences.md#set-a-default-gitlab-duo-namespace), then request a review again.

### `Error DCR4005`

You might get an error that states
`Code Review Flow could not obtain the required authentication tokens to connect to the GitLab AI Gateway and the GitLab API. Please request a new review. If the issue persists, contact your administrator. Error code: DCR4005`.

Code Review Flow requires authentication tokens to connect to the GitLab AI Gateway and the GitLab API. This error occurs when those tokens cannot be generated, usually due to an incorrect GitLab Duo setup or a transient infrastructure issue.

For self-managed instances, ask your administrator to verify the [GitLab Duo configuration](../../../../administration/gitlab_duo/configure/gitlab_self_managed.md).

### `Error DCR4006`

You might get an error that states
`Code Review Flow could not add the service account to this project. Contact your administrator to verify that the service account has the required project access. Error code: DCR4006`.

This error occurs when the service account cannot be added as a member of the project. This can happen when a group membership lock is enabled or the service account does not have the required access.

Contact your administrator and ask them to verify that the service account can be added to the project as a developer.

### `Error DCR4007`

You might get an error that states
`Code Review Flow is not available for this project. Contact your administrator to verify that the flow is enabled and the required configuration is in place. Error code: DCR4007`.

This error occurs when the flow is disabled or the required configuration is missing for the project.

Contact your administrator and ask them to verify that
[the flow is enabled](_index.md#turn-foundational-flows-on-or-off) for the project.

### `Error DCR4008`

You might get an error that states
`Code Review Flow could not create the required CI/CD pipeline. Please request a new review. If the problem persists, contact your administrator. Error code: DCR4008`.

This error occurs when Code Review Flow cannot create or configure the CI/CD pipeline to run the review because of runner availability issues or internal configuration problems.

Try to restart the review. If the error persists, contact your administrator.

### `Error DCR4009`

You might get an error that states
`Code Review Flow could not retrieve the source branch for this merge request. Please request a new review. Error code: DCR4009`.

This error occurs when Code Review Flow is unable to retrieve the source branch for the merge request.

Try to restart the review.

### `Error DCR5000`

You might get an error that states
`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`.

This error occurs when GitLab Duo Agent Platform is unable to start Code Review Flow due to an internal error.

Try to restart the review. If the error persists, contact your administrator.

### Missing context in large merge request reviews

Code Review Flow might miss context when a merge request contains many large changed files.

This can occur when the pre-scan results exceed the
[file and context limits](#file-and-context-limits) and the data is truncated before the review
stage runs.

To improve the review:

- Split the merge request into smaller merge requests.
- [Exclude context](../../context.md#exclude-context-from-gitlab-duo) for files that are not
  relevant to the review.
- Ask a Maintainer or Owner to
  [select Claude Sonnet 4.6 Vertex](../../../gitlab_duo/model_selection.md#select-a-model-for-a-feature)
  for Code Review. Sonnet 4.6 Vertex has a larger context window than the default model.

### Configuration diagnostic script

If you cannot identify the cause of a Code Review Flow issue from the documented error codes, you
can run a diagnostic script to check your GitLab Duo configuration.

The script checks the full configuration chain required for Code Review Flow, including checks that
apply to all GitLab Duo Agent Platform features.

For more information, see [run the configuration diagnostic script](../../troubleshooting.md#run-the-configuration-diagnostic-script).

## Related topics

- [GitLab Duo in merge requests](../../../project/merge_requests/duo_in_merge_requests.md)
- [Agent Platform AI models](../../model_selection.md)
