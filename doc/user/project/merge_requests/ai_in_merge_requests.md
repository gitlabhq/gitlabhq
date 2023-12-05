---
stage: Create
group: Code Review
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo in merge requests **(ULTIMATE SAAS EXPERIMENT)**

AI-assisted features in merge requests are designed to provide contextually relevant information during the lifecycle of a merge request.

Additional information on enabling these features and maturity can be found in our [GitLab Duo overview](../../ai_features.md).

## Fill in merge request templates

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10591) in GitLab 16.3 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is an [Experiment](../../../policy/experiment-beta-support.md) on GitLab.com.

Merge requests in projects often have [templates](../description_templates.md#create-a-merge-request-template) defined that need to be filled out. This helps reviewers and other users understand the purpose and changes a merge request might propose.

When creating a merge request, GitLab Duo can generate a description for the merge request based on the contents of the template. This fills in the template and replaces the current contents of the description.

To generate the description:

1. Create a new merge request, go to the **Description** field.
1. Select **AI Actions** (**{tanuki}**).
1. Select **Fill in merge request template**.

The updated description is applied to the box. You can edit or revise this description before you finish creating your merge request.

Provide feedback on this experimental feature in [issue 416537](https://gitlab.com/gitlab-org/gitlab/-/issues/416537).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Title of the merge request
- Contents of the description
- Diff of changes between the source branch's head and the target branch

## Summarize merge request changes

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10401) in GitLab 16.2 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is an [Experiment](../../../policy/experiment-beta-support.md) on GitLab.com.

GitLab Duo Merge request summaries are available on the merge request page in:

- The **Merge request summaries** dialog.
- The To-Do list.
- Email notifications.

Provide feedback on this experimental feature in [issue 408726](https://gitlab.com/gitlab-org/gitlab/-/issues/408726).

**Data usage**: The diff of changes between the source branch's head and the target branch is sent to the large language model.

## Summarize my merge request review

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10466) in GitLab 16.0 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is an [Experiment](../../../policy/experiment-beta-support.md) on GitLab.com.

When you've completed your review of a merge request and are ready to [submit your review](reviews/index.md#submit-a-review), generate a GitLab Duo Code review summary:

1. When you are ready to submit your review, select **Finish review**.
1. Select **AI Actions** (**{tanuki}**).
1. Select **Summarize my code review**.

The summary is displayed in the comment box. You can edit and refine the summary prior to submitting your review.

Merge request review summaries are also automatically generated when you submit your review. These automatically generated summaries are available on the merge request page in the **Merge request summaries** dialog, the To-Do list, and in email notifications.

Provide feedback on this experimental feature in [issue 408991](https://gitlab.com/gitlab-org/gitlab/-/issues/408991).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Draft comment's text

## Generate messages for merge or squash commits

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10453) in GitLab 16.2 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is an [Experiment](../../../policy/experiment-beta-support.md) on GitLab.com.

When preparing to merge your merge request you may wish to edit the proposed squash or merge commit message.

To generate a commit message with GitLab Duo:

1. Select the **Edit commit message** checkbox on the merge widget.
1. Select **Create AI-generated commit message**.
1. Review the commit message provide and choose **Insert** to add it to the commit.

Provide feedback on this experimental feature in [issue 408994](https://gitlab.com/gitlab-org/gitlab/-/issues/408994).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Contents of the file
- The file name

## Generate suggested tests in merge requests

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/10366) in GitLab 16.0 as an [Experiment](../../../policy/experiment-beta-support.md#experiment).

This feature is an [Experiment](../../../policy/experiment-beta-support.md) on GitLab.com.

Use GitLab Duo Test generation in a merge request to see a list of suggested tests for the file you are reviewing. This functionality can help determine if appropriate test coverage has been provided, or if you need more coverage for your project.

View a [click-through demo](https://go.gitlab.com/Xfp0l4).

To generate a test suggestion:

1. In a merge request, select the **Changes** tab.
1. On the header for the file, in the upper-right corner, select **Options** (**{ellipsis_v}**).
1. Select **Suggest test cases**.

The test suggestion is generated in a sidebar. You can copy the suggestion to your editor and use it as the start of your tests.

Feedback on this experimental feature can be provided in [issue 408995](https://gitlab.com/gitlab-org/gitlab/-/issues/408995).

**Data usage**: When you use this feature, the following data is sent to the large language model referenced above:

- Contents of the file
- The file name
