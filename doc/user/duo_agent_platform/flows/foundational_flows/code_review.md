---
stage: AI-powered
group: Code Creation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Code Review Flow
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Core, or Pro
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as [a beta](../../../../policy/development_stages_support.md) in GitLab [18.6](https://gitlab.com/groups/gitlab-org/-/epics/18645) [with a flag](../../../../administration/feature_flags/_index.md) named `duo_code_review_on_agent_platform`. Disabled by default.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

The Code Review Flow helps you accelerate MR cycles with agentic AI code reviews.
It provides enhanced contextual understanding of code changes, MR comments, code repositories, and linked issues.

This flow is available in the GitLab UI only.

## Use the flow

To trigger a Code Review Flow on a merge request:

1. On the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. Use one of these methods to trigger the review:
   - Assign the review to `@GitLabDuo`
   - Mention `@GitLabDuo` in a comment

You can interact with GitLab Duo by:

- Replying to its review comments to ask for clarification or alternative approaches
- Mentioning `@GitLabDuo` in any discussion thread to ask follow-up questions

### Run Code Review Flow automatically

You can configure automatic code reviews for projects or groups to ensure all merge requests receive an initial review by GitLab Duo:

- [Enable automatic reviews for a project](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-a-project)
- [Enable automatic reviews for groups](../../../project/merge_requests/duo_in_merge_requests.md#automatic-reviews-from-gitlab-duo-for-groups-and-applications)

When enabled, GitLab Duo automatically reviews merge requests unless they are marked as draft or contain no changes.

### Custom instructions

Customize the Code Review Flow's behavior using repository-specific review instructions. You can guide the agent to:

- Focus on specific code quality aspects (security, performance, maintainability)
- Enforce coding standards and best practices unique to your project
- Target specific file patterns with tailored review criteria
- Provide more detailed explanations for certain types of changes

To configure custom instructions, follow the [custom MR review instructions documentation](../../../project/merge_requests/duo_in_merge_requests.md#customize-instructions-for-gitlab-duo-code-review).

## Differences from classic Duo Code Review

While the Code Review Flow provides the same core functionality as the classic Duo Code Review, the GitLab Duo Agent Platform implementation offers:

- Improved context awareness: Better understanding of repository structure and cross-file dependencies.
- Agentic capabilities: Multi-step reasoning for more thorough analysis.
- Modern architecture: Built on the scalable Duo Agent Platform.

All existing features including custom instructions, automatic reviews, and interaction patterns remain compatible.
