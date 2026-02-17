---
stage: AI-powered
group: AI Coding
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Use AI-assisted features for relevant information about a merge request.
title: GitLab Duo in merge requests
---

{{< alert type="disclaimer" />}}

GitLab Duo is designed to provide contextually relevant information during the lifecycle of a merge request.

## Generate a description by summarizing code changes

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../../gitlab_duo/model_selection.md#default-models)
- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10401) in GitLab 16.2 as an [experiment](../../../policy/development_stages_support.md#experiment).
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/429882) to beta in GitLab 16.10.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186862) to Claude 3.7 Sonnet in GitLab 17.10
- Feature flag `add_ai_summary_for_new_mr` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186108) in GitLab 17.11.
- Changed to include Premium in GitLab 18.0.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193208) to Claude 4.0 Sonnet in GitLab 18.1.

{{< /history >}}

When you create or edit a merge request, use GitLab Duo Merge Request Summary
to create a merge request description.

1. [Create a new merge request](creating_merge_requests.md).
1. In the **Description** field, put your cursor where you want to insert the description.
1. On the toolbar above the text area, select **Summarize code changes** ({{< icon name="tanuki-ai" >}}).

   ![Above the text area, a toolbar displays a "Summarize code changes" button.](img/merge_request_ai_summary_v17_6.png)

The description is inserted where your cursor was.

<i class="fa-youtube-play" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=CKjkVsfyFd8&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

Provide feedback on this feature in [issue 443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236).

Data usage: The diff of changes between the source branch's head and the target branch is sent to the large language model.

## Use GitLab Duo to review your code

GitLab Duo can review your merge request for potential errors and provide feedback on alignment to
standards.

When you request a review from `@GitLabDuo`, one of the following features runs:

- [Code Review Flow](../../duo_agent_platform/flows/foundational_flows/code_review.md): The new flow
  available through the GitLab Duo Agent Platform. Uses GitLab Credits.
- [GitLab Duo Code Review (Classic)](../../gitlab_duo/code_review_classic.md): The classic code
  review functionality.

The review feature that runs depends on the add-on of the user that starts the GitLab Duo review:

- Manual review requests: The user who requests the review.
- Automatic reviews: The user who authors the merge request.
- Merge requests that start in draft: The user who marks the MR as ready.

Because the review feature is based on the requesting user's add-on, both features can run in the
same project.

### How the review features compare

While you interact with both review features the same way, Code Review Flow offers enhanced
capabilities compared to GitLab Duo Code Review (Classic):

- Improved context awareness: Better understanding of repository structure and cross-file
  dependencies.
- Agentic capabilities: Multi-step reasoning for more thorough analysis.
- Modern architecture: Built on the scalable GitLab Duo Agent Platform.

Both features support automatic reviews, custom instructions, and custom comments.

## Summarize a code review

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../../gitlab_duo/model_selection.md#default-models)
- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10466) in GitLab 16.0 as an [experiment](../../../policy/development_stages_support.md#experiment).
- Feature flag `summarize_my_code_review` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182448) in GitLab 17.10.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183873) to Claude 3.7 Sonnet in GitLab 17.11.
- Changed to include Premium in GitLab 18.0.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193685) to Claude 4.0 Sonnet in GitLab 18.1.

{{< /history >}}

When you've completed your review of a merge request and are ready to [submit your review](reviews/_index.md#submit-a-review), use GitLab Duo Code Review Summary to generate a summary of your comments.

1. On the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and find the merge request you want to review.
1. When you are ready to submit your review, select **Finish review**.
1. Select **Add Summary**.

The summary is displayed in the comment box. You can edit and refine the summary before you submit your review.

<i class="fa-youtube-play" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=Bx6Zajyuy9k)

Provide feedback on this experimental feature in [issue 408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991).

Data usage: When you use this feature, the following data is sent to the large language model:

- Draft comment's text

## Generate a merge commit message

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise, GitLab Duo with Amazon Q
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< collapsible title="Model information" >}}

- [Default LLM](../../gitlab_duo/model_selection.md#default-models)
- LLM for Amazon Q: Amazon Q Developer
- Available on [GitLab Duo with self-hosted models](../../../administration/gitlab_duo_self_hosted/_index.md)

{{< /collapsible >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10453) in GitLab 16.2 as an [experiment](../../../policy/development_stages_support.md#experiment) [with a flag](../../../administration/feature_flags/_index.md) named `generate_commit_message_flag`. Disabled by default.
- Feature flag `generate_commit_message_flag` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339) in GitLab 17.2.
- Feature flag `generate_commit_message_flag` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262) in GitLab 17.7.
- Changed to include Premium in GitLab 18.0.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/193793) to Claude 4.0 Sonnet in GitLab 18.1.
- Changed to support Amazon Q in GitLab 18.3.

{{< /history >}}

When preparing to merge your merge request, edit the proposed merge commit message
by using GitLab Duo Merge Commit Message Generation.

1. On the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Code** > **Merge requests** and find your merge request.
1. Select the **Edit commit message** checkbox on the merge widget.
1. Select **Generate commit message**.
1. Review the commit message provided and choose **Insert** to add it to the commit.

<i class="fa-youtube-play" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=fUHPNT4uByQ)

Data usage: When you use this feature, the following data is sent to the large language model:

- Contents of the file
- The filename

## Related topics

- [Control GitLab Duo availability](../../gitlab_duo/turn_on_off.md)
- [All GitLab Duo features](../../gitlab_duo/_index.md)

## Troubleshooting

When working with GitLab Duo in Merge Requests, you might encounter the following issues.

### Response not received

If you ask GitLab Duo for a review by mentioning or replying to `@GitLabDuo`,
and do not receive a response, this might be because you do not have the
appropriate GitLab Duo add-on.

To check your GitLab Duo add-on, ask your group Owner to check the group's
[GitLab Duo seat assignments](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users).

To change your GitLab Duo add-on, contact your administrator.

### Unable to assign GitLab Duo to review

If you cannot assign GitLab Duo as a reviewer, it might be because you do not
have the appropriate GitLab Duo add-on.

To check your GitLab Duo add-on, ask your group Owner to check the group's
[GitLab Duo seat assignments](../../../subscriptions/subscription-add-ons.md#view-assigned-gitlab-duo-users).

To change your GitLab Duo add-on, contact your administrator.

### Error: `GitLab Duo Code Review was not automatically added...`

If you try to create a merge request with automatic reviews from GitLab Duo
turned on, you might get the following error message:

```plaintext
GitLab Duo Code Review was not automatically added because your account requires
GitLab Duo Enterprise. Contact your administrator to upgrade your account.
```

Contact your administrator to ask them to
[purchase a GitLab Duo Enterprise seat](../../../subscriptions/subscription-add-ons.md#purchase-gitlab-duo)
and assign it to you.
