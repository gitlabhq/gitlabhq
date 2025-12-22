---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Code Review Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core or Pro
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- LLM: Anthropic [Claude 4.0 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-sonnet-4)
- Available on [GitLab Duo with self-hosted models](../../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- Introduced as [a beta](../../../../policy/development_stages_support.md) in GitLab [18.6](https://gitlab.com/groups/gitlab-org/-/epics/18645) [with a flag](../../../../administration/feature_flags/_index.md) named `duo_code_review_on_agent_platform`. Disabled by default.
- Feature flag `duo_code_review_on_agent_platform` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/217209) in GitLab 18.8.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The Code Review Flow helps you streamline code reviews with agentic AI.

This flow:

- Analyzes code changes, merge request comments, and linked issues.
- Provides enhanced contextual understanding of repository structure and cross-file dependencies.
- Delivers detailed review comments with actionable feedback.
- Supports custom review instructions tailored to your project.

This flow is available in the GitLab UI only.

The Code Review Flow is [different from classic GitLab Duo Code Review](#differences-from-classic-gitlab-duo-code-review).

## Use the flow

Prerequisites:

- Ensure you meet [the other prerequisites](../_index.md#prerequisites).

To trigger a Code Review Flow on a merge request:

1. On the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. Use one of these methods to trigger the review:
   - Assign the review to `@GitLabDuo`
   - Mention `@GitLabDuo` in a comment

You can interact with GitLab Duo by:

- Replying to its review comments to ask for clarification or alternative approaches.
- Mentioning `@GitLabDuo` in any discussion thread to ask follow-up questions.

### Automatic code reviews

You can configure automatic code reviews for projects or groups to ensure all merge requests receive
an initial review by GitLab Duo.

Learn how to [enable automatic reviews for a project](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-a-project).

Learn how to [enable automatic reviews for groups and applications](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-groups-and-applications).

### Custom code review instructions

Customize the behavior of Code Review Flow with repository-specific review instructions. You can
guide GitLab Duo to:

- Focus on specific code quality aspects (such as security, performance, and maintainability).
- Enforce coding standards and best practices unique to your project.
- Target specific file patterns with tailored review criteria.
- Provide more detailed explanations for certain types of changes.

To configure custom instructions, see [customize instructions for GitLab Duo](../../../project/merge_requests/duo_in_merge_requests.md#customize-review-instructions-for-gitlab-duo).

### Custom code review comments

You can customize the format of code review comments for GitLab Duo to follow.

To configure custom comments, see [customized code review comments](../../../project/merge_requests/duo_in_merge_requests.md#customized-code-review-comments).

## Differences from classic GitLab Duo Code Review

While the Code Review Flow provides the same core functionality as the classic
[GitLab Duo Code Review](../../../project/merge_requests/duo_in_merge_requests.md#gitlab-duo-code-review),
the GitLab Duo Agent Platform implementation offers:

- Improved context awareness: Better understanding of repository structure and cross-file dependencies.
- Agentic capabilities: Multi-step reasoning for more thorough analysis.
- Modern architecture: Built on the scalable GitLab Duo Agent Platform.

All existing features including custom instructions, automatic reviews, and interaction patterns
remain compatible.
