---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Code Review Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Available on [GitLab Duo with self-hosted models](../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../../../policy/development_stages_support.md) in GitLab [18.7](https://gitlab.com/groups/gitlab-org/-/epics/18645) [with a flag](../../../../administration/feature_flags/_index.md) named `duo_code_review_on_agent_platform`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/work_items/585273) in GitLab 18.8. Feature flag `duo_code_review_on_agent_platform` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209).

{{< /history >}}

> [!note]
> Depending on your add-on, you might have access to GitLab Duo Code Review (Classic) instead.
> Learn how [the two features compare](../../../../user/project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code).

The Code Review Flow helps you streamline code reviews with agentic AI.

This flow:

- Analyzes code changes, merge request comments, and linked issues.
- Provides enhanced contextual understanding of repository structure and cross-file dependencies.
- Delivers detailed review comments with actionable feedback.
- Supports custom review instructions tailored to your project.

This flow is available in the GitLab UI only.

## Use the flow

Prerequisites:

- Ensure you meet the [Agent Platform prerequisites](../../../../user/duo_agent_platform/_index.md#prerequisites).
- Ensure that **Allow foundational flows** and **Code Review** are [turned on](../../../gitlab_duo/turn_on_off.md#turn-gitlab-duo-on-or-off) for the top-level group.

To use the Code Review Flow on a merge request:

1. On the left sidebar, select **Code** > **Merge requests** and find your merge request.
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

## Custom code review instructions

Customize the behavior of Code Review Flow with repository-specific review instructions. You can
guide GitLab Duo to:

- Focus on specific code quality aspects (such as security, performance, and maintainability).
- Enforce coding standards and best practices unique to your project.
- Target specific file patterns with tailored review criteria.
- Provide more detailed explanations for certain types of changes.

To configure custom instructions, see [customize instructions for GitLab Duo](../../../gitlab_duo/customize_duo/review_instructions.md).

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

1. On the top bar, select **Search or go to** and find your project.
1. Select **Settings** > **Merge requests**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

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

1. On the top bar, select **Search or go to** and find your group.
1. Select **Settings** > **General**.
1. Expand the **Merge requests** section.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

To enable automatic reviews for all projects:

1. In the upper-right corner, select **Admin**.
1. Select **Settings** > **General**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

Settings cascade from application to group to project. More specific settings override broader ones.

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

Wait a few minutes for the service account to activate, then try again. If the error persists, contact your administrator.

### `Error DCR4002`

You might get an error that states
`No GitLab Credits remain for this billing period. To continue using Code Review Flow, contact your administrator. Error code: DCR4002`.

This error occurs when you have used all of your allocated GitLab Credits for the current billing period.

Contact your administrator to purchase additional credits or wait for your credits to reset at the start of the next billing period.

### `Error DCR5000`

You might get an error that states
`Something went wrong while starting Code Review Flow. Please try again later. Error code: DCR5000`.

This error occurs when GitLab Duo Agent Platform is unable to start Code Review Flow due to an internal error.

Try to restart the review. If the error persists, contact your administrator.

## Related topics

- [GitLab Duo in merge requests](../../../../user/project/merge_requests/duo_in_merge_requests.md)
