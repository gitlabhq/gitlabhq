---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Duo with Amazon Q

DETAILS:
**Tier:** Ultimate
**Offering:** Self-managed
**Status:** Preview/Beta

> - Introduced as [beta](../../policy/development_stages_support.md#beta) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `amazon_q_integration`. Disabled by default.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is Preview/Beta and is available for testing, but not ready for production use.

At Re:Invent 2024, Amazon announced the GitLab Duo with Amazon Q integration.
With this integration, you can automate tasks and increase productivity.

On December 3, 2024, the private fork of the GitLab codebase where Amazon
and GitLab have been collaborating on the integration was unveiled.
Select GitLab customers have been invited to a test GitLab instance
so they can start to experiment right away.

## Set up GitLab Duo with Amazon Q

To access GitLab Duo with Amazon Q, you must request [access to a lab environment](https://about.gitlab.com/aws).
Alternately, you can [set up the GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab/-/blob/gitlab-duo-with-amazon-q-preview/README.md?ref_type=heads).

## Use GitLab Duo with Amazon Q in an issue

To invoke GitLab Duo with Amazon Q for an issue, you will use [quick actions](../project/quick_actions.md).

### Turn an idea into a merge request

Turn an idea in an issue into a merge request that contains the proposed implementation.

Amazon Q uses the issue title and description, along with project context, to create a merge request
with code to address the issue.

#### From the issue description

1. Create a new issue, or open an existing issue and in the upper-right corner, select **Edit**.
1. In the description box, type `/q dev`.
1. Select **Save changes**.

#### From a comment

1. In the issue, in a comment, type `/q dev`.
1. Select **Comment**.

### Upgrade Java

Amazon Q can analyze Java 8 or 11 code and determine the necessary Java changes to update the code to Java 17.

Prerequisites:

- You must [have a runner configured for your project](https://docs.gitlab.com/runner/register/).

To upgrade Java:

1. Create an issue.
1. In the issue title and description, explain that you want to upgrade Java.
   You do not need to enter version details. Amazon Q can determine the version.
1. Save the issue. Then, in a comment, type `/q transform`.
1. Select **Comment**.

A merge request with the code changes needed for the upgrade is created.

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
