---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Duo Code Review (non-agentic)
---

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](model_selection.md#default-models)
- Available on [GitLab Duo with self-hosted models](../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14825) in GitLab 17.5 as an [experiment](../../policy/development_stages_support.md#experiment) behind two feature flags named [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) and [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632), both disabled by default.
- Feature flags [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) and [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632) enabled by default on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in 17.10.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/516234) to beta in GitLab 17.10.
- Changed to include Premium in GitLab 18.0.
- Feature flag `ai_review_merge_request` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190639) in GitLab 18.1.
- Feature flag `duo_code_review_chat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190640) in GitLab 18.1.
- Generally available in GitLab 18.1.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/524929) to be available on GitLab Duo with self-hosted models in beta in GitLab 18.3.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/548975) to be generally available on GitLab Duo with self-hosted models in GitLab 18.4.

{{< /history >}}

> [!note]
> Depending on your add-on, GitLab runs one of two code review features:
>
> - Code Review Flow: the agentic version, part of GitLab Duo Agent Platform.
> - GitLab Duo Code Review: the non-agentic version, available only for users with the GitLab Duo Enterprise add-on.
>
> This page describes the non-agentic version.
> Learn how [the two features compare](../project/merge_requests/duo_in_merge_requests.md#use-gitlab-duo-to-review-your-code).

GitLab Duo Code Review helps you streamline code reviews in your projects.

## Use GitLab Duo Code Review

When your merge request is ready to be reviewed, use GitLab Duo Code Review to perform an initial review:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. In a comment box, enter the quick action `/assign_reviewer @GitLabDuo`, or assign GitLab Duo as reviewer.

<i class="fa-youtube-play" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=SG3bhD1YjeY&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW&index=2)

Provide feedback on this feature in [issue 517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

### Contextual awareness

When you use GitLab Duo Code Review, the following data is sent to the large language model:

- Merge request title
- Merge request description
- File contents before changes applied (for context)
- Merge request diffs
- Filenames
- Custom instructions

To specify content to exclude, see [exclude context from Code Review](context.md#exclude-context-from-code-review).

#### Behavior on large merge requests

GitLab Duo Code Review sends the merge request diffs and the original contents of changed files
to the model. The combined prompt is subject to the [selected model's](model_selection.md) context window.

For large merge requests, GitLab Duo Code Review uses a fallback to improve the chance of a
successful review:

1. The initial request includes the merge request diffs and the original file contents.
1. If that request fails, GitLab Duo Code Review automatically retries without the original file
   contents.
1. If the retry also fails, GitLab Duo Code Review returns a generic error message.

The retry without file contents reduces prompt size, but also reduces the context the model has when
reviewing your changes. Comments might be less specific than a review that includes the original
file contents.

The AI Gateway request timeout for GitLab Duo Code Review is 120 seconds. Reviews that do not complete
in this window also surface as generic errors.

To reduce the risk of failed reviews on large merge requests:

- Split large merge requests into smaller ones.
- [Exclude context](context.md#exclude-context-from-code-review) for files that are not relevant to
  the review.
- Ask a Maintainer or Owner to [select a different model](model_selection.md#select-a-model-for-a-feature)
  for Code Review.

## Interact with GitLab Duo in reviews

You can mention `@GitLabDuo` in comments to interact with GitLab Duo on your merge request. You can
ask follow-up questions on its review comments, or ask questions on any discussion thread in your
merge request.

Interactions with GitLab Duo can help to improve the suggestions and feedback as you work to improve
your merge request.

Feedback provided to GitLab Duo does not influence later reviews of other merge requests.
There is a feature request to add this functionality, see [issue 560116](https://gitlab.com/gitlab-org/gitlab/-/issues/560116).

## Custom code review instructions

You can create custom MR review instructions to ensure consistent and specific
code review standards in your project.

For more information, see [customize review instructions for GitLab Duo](customize_duo/review_instructions.md).

## Automatic reviews from GitLab Duo for a project

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) to a UI setting in GitLab 18.0.

{{< /history >}}

Automatic reviews from GitLab Duo ensure that all merge requests in your project receive an initial review.
After a merge request is created, GitLab Duo reviews it unless:

- It's marked as draft. For GitLab Duo to review the merge request, mark it ready.
- It contains no changes. For GitLab Duo to review the merge request, add changes to it.

Prerequisites:

- You must have at least the [Maintainer role](../permissions.md) in a project.

To enable `@GitLabDuo` to automatically review merge requests:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Merge requests**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

## Automatic reviews from GitLab Duo for groups and applications

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/554070) in GitLab 18.4 as a [beta](../../policy/development_stages_support.md#beta) [with a flag](../../administration/feature_flags/_index.md) named `cascading_auto_duo_code_review_settings`. Disabled by default.
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

## Troubleshooting

### Review fails on a large merge request

GitLab Duo Code Review might fail to post a review on merge requests with many large changed files.
Common causes include:

- The combined size of diffs and original file contents exceeds the model's context window.
- The AI Gateway request takes longer than 120 seconds.

For details on the retry and timeout behavior, see
[behavior on large merge requests](#behavior-on-large-merge-requests).

To work around the failure:

- Split the merge request into smaller merge requests.
- [Exclude context](context.md#exclude-context-from-code-review) for files that are not relevant to
  the review.

For more information, see [issue 596794](https://gitlab.com/gitlab-org/gitlab/-/work_items/596794).

## Related topics

- [GitLab Duo in merge requests](../project/merge_requests/duo_in_merge_requests.md)
