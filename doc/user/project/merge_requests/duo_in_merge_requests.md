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

- Tier: Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- Offering: GitLab.com
- Status: Beta
- LLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10401) in GitLab 16.2 as an [experiment](../../../policy/development_stages_support.md#experiment).
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/429882) to beta in GitLab 16.10.
- Changed to require GitLab Duo add-on in GitLab 17.6 and later.

{{< /history >}}

When you create or edit a merge request, use GitLab Duo Merge Request Summary
to create a merge request description.

1. [Create a new merge request](creating_merge_requests.md).
1. In the **Description** field, put your cursor where you want to insert the description.
1. On the toolbar above the text area, select **Summarize code changes** ({{< icon name="tanuki-ai" >}}).

   ![Above the text area, a toolbar displays a "Summarize code changes" button.](img/merge_request_ai_summary_v17_6.png)

The description is inserted where your cursor was.

Provide feedback on this feature in [issue 443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236).

**Data usage**: The diff of changes between the source branch's head and the target branch is sent to the large language model.

## Have GitLab Duo review your code

{{< details >}}

- Tier: Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Beta
- LLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/14825) in GitLab 17.5 as an [experiment](../../../policy/development_stages_support.md#experiment) behind two feature flags named [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) and [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632), both disabled by default.
- Feature flags [`ai_review_merge_request`](https://gitlab.com/gitlab-org/gitlab/-/issues/456106) and [`duo_code_review_chat`](https://gitlab.com/gitlab-org/gitlab/-/issues/508632) enabled by default on GitLab.com, GitLab Self-Managed, and GitLab Dedicated in 17.10.
- [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/516234) to beta in GitLab 17.10.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by two feature flags.
For more information, see the history.

{{< /alert >}}

When your merge request is ready to be reviewed, use GitLab Duo Code Review to perform an initial review:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. In a comment box, enter the quick action `/assign_reviewer @GitLabDuo`, or assign GitLab Duo as reviewer.

{{< alert type="note" >}}

Provide feedback on this feature in issue [517386](https://gitlab.com/gitlab-org/gitlab/-/issues/517386).

{{< /alert >}}

**Data usage**: When you use this feature, the following data is sent to the large language model:

- Contents of the file
- The filename

### Interact with GitLab Duo in reviews

You can mention `@GitLabDuo` in comments to interact with GitLab Duo on your merge request. You can ask follow-up questions on its review comments, or ask questions on any discussion thread in your merge request.

Interactions with GitLab Duo can help to improve the suggestions and feedback as you work to improve your merge request.

### Automatic reviews from GitLab Duo

To enable `@GitLabDuo` to automatically review merge requests, edit your
[merge request template](../../../user/project/description_templates.md#create-a-merge-request-template)
and add the line `/assign_reviewer @GitLabDuo`. Add this line to your default template,
and any other templates in your project where you want `@GitLabDuo` to perform a review.

Additional settings and configuration are planned. To that work, see
[issue 506537](https://gitlab.com/gitlab-org/gitlab/-/issues/506537).

## Summarize a code review

{{< details >}}

- Tier: Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- Status: Experiment
- LLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10466) in GitLab 16.0 as an [experiment](../../../policy/development_stages_support.md#experiment).
- Feature flag `summarize_my_code_review` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182448) in GitLab 17.10.

{{< /history >}}

When you've completed your review of a merge request and are ready to [submit your review](reviews/_index.md#submit-a-review), use GitLab Duo Code Review Summary to generate a summary of your comments.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find the merge request you want to review.
1. When you are ready to submit your review, select **Finish review**.
1. Select **Add Summary**.

The summary is displayed in the comment box. You can edit and refine the summary prior to submitting your review.

Provide feedback on this experimental feature in [issue 408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Draft comment's text

## Generate a merge commit message

{{< details >}}

- Tier: Ultimate with GitLab Duo Enterprise - [Start a trial](https://about.gitlab.com/solutions/gitlab-duo-pro/sales/?type=free-trial)
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated
- LLM: Anthropic [Claude 3.5 Sonnet](https://console.cloud.google.com/vertex-ai/publishers/anthropic/model-garden/claude-3-5-sonnet)

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10453) in GitLab 16.2 as an [experiment](../../../policy/development_stages_support.md#experiment) [with a flag](../../../administration/feature_flags.md) named `generate_commit_message_flag`. Disabled by default.
- Feature flag `generate_commit_message_flag` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158339) in GitLab 17.2.
- Feature flag `generate_commit_message_flag` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/173262) in GitLab 17.7.

{{< /history >}}

When preparing to merge your merge request, edit the proposed merge commit message
by using GitLab Duo Merge Commit Message Generation.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. Select the **Edit commit message** checkbox on the merge widget.
1. Select **Generate commit message**.
1. Review the commit message provided and choose **Insert** to add it to the commit.

**Data usage**: When you use this feature, the following data is sent to the large language model:

- Contents of the file
- The filename

## Related topics

- [Control GitLab Duo availability](../../ai_features_enable.md)
- [All GitLab Duo features](../../ai_features.md)
