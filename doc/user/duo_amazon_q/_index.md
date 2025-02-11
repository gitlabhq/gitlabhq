---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo with Amazon Q
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab Self-Managed
**Status:** Preview/Beta

> - Introduced as [beta](../../policy/development_stages_support.md#beta) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `amazon_q_integration`. Disabled by default.
> - Feature flag `amazon_q_integration` removed in GitLab 17.8.

NOTE:
If you have a Duo Pro or Duo Enterprise add-on, this feature is not available.

At Re:Invent 2024, Amazon announced the GitLab Duo with Amazon Q integration.
With this integration, you can automate tasks and increase productivity.

Select GitLab customers have been invited to a test GitLab instance
so they can start to experiment right away.

## Set up GitLab Duo with Amazon Q

To access GitLab Duo with Amazon Q, request [access to a lab environment](https://about.gitlab.com/partners/technology-partners/aws/#interest).
Alternately, if you have GitLab 17.8 or later, you can
[set it up on your GitLab Self-Managed instance](setup.md).

## Use GitLab Duo with Amazon Q in an issue

To invoke GitLab Duo with Amazon Q for an issue, you will use [quick actions](../project/quick_actions.md).

### Turn an idea into a merge request

Turn an idea in an issue into a merge request that contains the proposed implementation.

Amazon Q uses the issue title and description, along with project context, to create a merge request
with code to address the issue.

[View a walkthrough](https://gitlab.navattic.com/duo-q).

#### From the issue description

1. Create a new issue, or open an existing issue and in the upper-right corner, select **Edit**.
1. In the description box, type `/q dev`.
1. Select **Save changes**.

#### From a comment

1. In the issue, in a comment, type `/q dev`.
1. Select **Comment**.

### Upgrade Java

Amazon Q can analyze Java 8 or 11 code and determine the necessary Java changes to update the code to Java 17.

[View a walkthrough](https://gitlab.navattic.com/duo-q-transform).

Prerequisites:

- You must [have a runner and a CI/CD pipeline configured for your project](../../ci/_index.md).

To upgrade Java:

1. Create an issue.
1. In the issue title and description, explain that you want to upgrade Java.
   You do not need to enter version details. Amazon Q can determine the version.
1. Save the issue. Then, in a comment, type `/q transform`.
1. Select **Comment**.

A CI/CD job starts. A comment is displayed with the details and a link to the job.

- If the job is successful, a merge request with the code changes needed for the upgrade is created.
- If the job fails, a comment provides details about potential fixes.

## Use GitLab Duo with Amazon Q in a merge request

To invoke GitLab Duo with Amazon Q for a merge request, you will use [quick actions](../project/quick_actions.md).

### Review a merge request

Amazon Q can analyze your merge request and suggest improvements to your code.
It can find things like security issues, quality issues, inefficiencies,
and other errors.

1. Open your merge request.
1. On the **Overview** tab, in a comment, type `/q review`.
1. Select **Comment**.

Amazon Q performs a review of the merge request changes
and displays the results in comments.

### Make code changes based on feedback

Amazon Q can make code changes based on reviewer feedback.

1. Open a merge request that has reviewer feedback.
1. On the **Overview** tab, go to the comment you want to address.
1. Below the comment, in the **Reply** box, type `/q dev`.
1. Select **Add comment now**.

Amazon Q proposes changes to the merge request based on the reviewer's comments and feedback.

### Apply code changes based on feedback

Amazon Q can suggest code changes based on feedback in a specific merge request comment.

1. Open a merge request that has reviewer feedback.
1. On the **Overview** tab, go to the comment you want to address.
1. Type `/q fix`.
1. Select **Add comment now**.

Amazon Q proposes changes for the specific comment.

### Create test coverage

Generate new unit tests while you're having your merge request reviewed.
Amazon Q surfaces any missing unit test coverage in the proposed code changes.

To create test coverage:

1. Open your merge request.
1. On the **Changes** tab, select the lines you want to test.
1. In the comment, type `/q test`.
1. Select **Add comment now**.

- If the merge request includes a test file, it is updated with the suggested tests.
- If the merge request does not include a test file, Amazon Q populates a comment with the suggested tests.

## Related topics

- [Set up GitLab Duo with Amazon Q](setup.md)
- [GitLab Duo authentication and authorization](../gitlab_duo/security.md)
