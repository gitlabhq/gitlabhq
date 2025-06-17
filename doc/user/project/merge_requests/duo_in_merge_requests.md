---
stage: Create
group: Code Review
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
- LLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10401) in GitLab 16.2 as an [experiment](../../../policy/development_stages_support.md#experiment).
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/429882) to beta in GitLab 16.10.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186862) to Claude 3.7 Sonnet in GitLab 17.10
- Feature flag `add_ai_summary_for_new_mr` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/186108) in GitLab 17.11.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

When you create or edit a merge request, use GitLab Duo Merge Request Summary
to create a merge request description.

1. [Create a new merge request](creating_merge_requests.md).
1. In the **Description** field, put your cursor where you want to insert the description.
1. On the toolbar above the text area, select **Summarize code changes** ({{< icon name="tanuki-ai" >}}).

   ![Above the text area, a toolbar displays a "Summarize code changes" button.](img/merge_request_ai_summary_v17_6.png)

The description is inserted where your cursor was.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=CKjkVsfyFd8&list=PLFGfElNsQthZGazU1ZdfDpegu0HflunXW)

Provide feedback on this feature in [issue 443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236).

Data usage: The diff of changes between the source branch's head and the target branch is sent to the large language model.

## Have GitLab Duo review your code

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- LLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14825) in GitLab 17.5 as an [experiment](../../../policy/development_stages_support.md#experiment) behind two feature flags named [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) and [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632), both disabled by default.
- Feature flags [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) and [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632) enabled by default on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in 17.10.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/516234) to beta in GitLab 17.10.
- Changed to include Premium in GitLab 18.0.
- Feature flag `ai_review_merge_request` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190639) in GitLab 18.1.
- Feature flag `duo_code_review_chat` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/190640) in GitLab 18.1.
- Generally available in GitLab 18.1.

{{< /history >}}

When your merge request is ready to be reviewed, use GitLab Duo Code Review to perform an initial review:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. In a comment box, enter the quick action `/assign_reviewer @GitLabDuo`, or assign GitLab Duo as reviewer.

{{< alert type="note" >}}

Provide feedback on this feature in issue [517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

{{< /alert >}}

Data usage: When you use this feature, the following data is sent to the large language model:

- Contents of the changed files
- Filenames
- Merge request title
- Merge request description

### Interact with GitLab Duo in reviews

You can mention `@GitLabDuo` in comments to interact with GitLab Duo on your merge request. You can ask follow-up questions on its review comments, or ask questions on any discussion thread in your merge request.

Interactions with GitLab Duo can help to improve the suggestions and feedback as you work to improve your merge request.

### Automatic reviews from GitLab Duo

{{< history >}}

- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/506537) to a UI setting in GitLab 18.0.

{{< /history >}}

Automatic reviews from GitLab Duo ensure that all merge requests in your project receive an initial review.
After a merge request is created, GitLab Duo reviews it unless:

- It's marked as draft. For GitLab Duo to review the merge request, mark it ready.
- It contains no changes. For GitLab Duo to review the merge request, add changes to it.

Prerequisites:

- You must have at least the [Maintainer role](../../permissions.md) in a project.

To enable `@GitLabDuo` to automatically review merge requests:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Merge requests**.
1. In the **GitLab Duo Code Review** section, select **Enable automatic reviews by GitLab Duo**.
1. Select **Save changes**.

## Summarize a code review

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment
- LLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10466) in GitLab 16.0 as an [experiment](../../../policy/development_stages_support.md#experiment).
- Feature flag `summarize_my_code_review` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182448) in GitLab 17.10.
- LLM [updated](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183873) to Claude 3.7 Sonnet in GitLab 17.11.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

When you've completed your review of a merge request and are ready to [submit your review](reviews/_index.md#submit-a-review), use GitLab Duo Code Review Summary to generate a summary of your comments.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find the merge request you want to review.
1. When you are ready to submit your review, select **Finish review**.
1. Select **Add Summary**.

The summary is displayed in the comment box. You can edit and refine the summary prior to submitting your review.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=Bx6Zajyuy9k)

Provide feedback on this experimental feature in [issue 408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991).

Data usage: When you use this feature, the following data is sent to the large language model:

- Draft comment's text

## Generate a merge commit message

{{< details >}}

- Tier: Premium, Ultimate
- Add-on: GitLab Duo Enterprise
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- LLM: Anthropic [Claude 3.7 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-7-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10453) in GitLab 16.2 as an [experiment](../../../policy/development_stages_support.md#experiment) [with a flag](../../../administration/feature_flags.md) named `generate_commit_message_flag`. Disabled by default.
- Feature flag `generate_commit_message_flag` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339) in GitLab 17.2.
- Feature flag `generate_commit_message_flag` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262) in GitLab 17.7.
- Changed to include Premium in GitLab 18.0.

{{< /history >}}

When preparing to merge your merge request, edit the proposed merge commit message
by using GitLab Duo Merge Commit Message Generation.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. Select the **Edit commit message** checkbox on the merge widget.
1. Select **Generate commit message**.
1. Review the commit message provided and choose **Insert** to add it to the commit.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [Watch an overview](https://www.youtube.com/watch?v=fUHPNT4uByQ)

Data usage: When you use this feature, the following data is sent to the large language model:

- Contents of the file
- The filename

## Related topics

- [Control GitLab Duo availability](../../ai_features_enable.md)
- [All GitLab Duo features](../../ai_features.md)
