---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo in merge requests

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status**: Experiment

AI-assisted features in merge requests are designed to provide contextually relevant information during the lifecycle of a merge request.

Additional information on enabling these features and maturity can be found in our [GitLab Duo overview](../../ai_features.md).

## Summarize merge request changes

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10401) in GitLab 16.2 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is in [Beta](../../../policy/experiment-beta-support.md) on GitLab.com.

GitLab Duo Merge request summaries can be added to your merge request description when creating or editing a merge request. To add a summary, select **Summarize code changes**. The generated summary is added to the merge request description where your cursor is.

![merge_request_ai_summary_v16_11](img/merge_request_ai_summary_v16_11.png)

Provide feedback on this feature in [issue 443236](https://gitlab.com/gitlab-org/gitlab/-/issues/443236).

**Data usage**: The diff of changes between the source branch's head and the target branch is sent to the large language model.

## Summarize my merge request review

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10466) in GitLab 16.0 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is an [Experiment](../../../policy/experiment-beta-support.md) on GitLab.com.

When you've completed your review of a merge request and are ready to [submit your review](reviews/index.md#submit-a-review), generate a GitLab Duo Code review summary:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find the merge request you want to review.
1. When you are ready to submit your review, select **Finish review**.
1. Select **Summarize my pending comments**.

The summary is displayed in the comment box. You can edit and refine the summary prior to submitting your review.

Provide feedback on this experimental feature in [issue 408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Draft comment's text

## Fill in merge request templates

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10591) in GitLab 16.3 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).
> - [Changed](https://gitlab.com/gitlab-org/gitlab/-/issues/429882) to Beta in GitLab 16.10

This feature is in [Beta](../../../policy/experiment-beta-support.md) on GitLab.com.

Merge requests in projects often have [templates](../description_templates.md#create-a-merge-request-template) defined that need to be filled out. This helps reviewers and other users understand the purpose and changes a merge request might propose.

When creating a merge request, GitLab Duo can generate a description for the merge request based on the contents of the template. This fills in the template and replaces the current contents of the description.

To generate the description:

1. [Create a new merge request](creating_merge_requests.md), and go to the **Description** field.
1. Select **AI Actions** (**{tanuki}**).
1. Select **Fill in merge request template**.

The updated description is applied to the box. You can edit or revise this description before you finish creating your merge request.

Provide feedback on this experimental feature in [issue 416537](https://gitlab.com/gitlab-org/gitlab/-/issues/416537).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Title of the merge request
- Contents of the description
- Diff of changes between the source branch's head and the target branch

## Generate messages for merge or squash commits

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10453) in GitLab 16.2 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is an [Experiment](../../../policy/experiment-beta-support.md) on GitLab.com.

When preparing to merge your merge request you might wish to edit the proposed squash or merge commit message.

To generate a commit message with GitLab Duo:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Code > Merge requests** and find your merge request.
1. Select the **Edit commit message** checkbox on the merge widget.
1. Select **Create AI-generated commit message**.
1. Review the commit message provide and choose **Insert** to add it to the commit.

Provide feedback on this experimental feature in [issue 408994](https://gitlab.com/gitlab-org/gitlab/-/issues/408994).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Contents of the file
- The filename

<!--- start_remove The following content will be removed on remove_date: '2024-04-12' -->

## Generate suggested tests in merge requests

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10366) in GitLab 16.0 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141086) to GitLab Duo Chat in GitLab 16.8.

This feature was [moved](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/141086)
into GitLab Duo Chat in GitLab 16.8. Find more information in
[Write tests in the IDE](../../gitlab_duo_chat.md#write-tests-in-the-ide).

<!--- end_remove -->
