---
stage: AI-powered
group: AI Framework
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Duo with Amazon Q
---

{{< details >}}

- Tier: Ultimate
- Add-on: GitLab Duo with Amazon Q
- Offering: GitLab Self-Managed
- Status: Preview/Beta

{{< /details >}}

{{< history >}}

- Introduced as [beta](../../policy/development_stages_support.md#beta) in GitLab 17.7 [with a flag](../../administration/feature_flags.md) named `amazon_q_integration`. Disabled by default.
- Feature flag `amazon_q_integration` removed in GitLab 17.8.

{{< /history >}}

{{< alert type="note" >}}

If you have a GitLab Duo Pro or Duo Enterprise add-on, this feature is not available.

{{< /alert >}}

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
- Your `pom.xml` file must have a [source and target](https://maven.apache.org/plugins/maven-compiler-plugin/examples/set-compiler-source-and-target.html).

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

### View suggested fixes

After Amazon Q has reviewed your code and added comments that explain potential issues,
Amazon Q can reply to these comments with suggested fixes.

1. Open a merge request that has feedback from Amazon Q.
1. On the **Overview** tab, go to the comment you want to address.
1. Type `/q fix`.
1. Select **Add comment now**.

Amazon Q proposes fixes for the issue in the comment.

### Generate unit tests

Generate new unit tests while you're having your merge request reviewed.
Amazon Q surfaces any missing unit test coverage in the proposed code changes.

To generate unit tests for all code changes:

1. Open your merge request.
1. On the **Overview** tab, in a comment, type `/q test`.
1. Select **Comment**.

Amazon Q populates a comment with the suggested tests.

### Create test coverage for selected lines

Generate new unit tests for specific lines of code in your merge request.

To create test coverage for selected lines:

1. Open your merge request.
1. On the **Changes** tab, select the lines you want to test.
1. In the comment, type `/q test`.
1. Select **Add comment now**.

- If the merge request includes a test file, it is updated with the suggested tests.
- If the merge request does not include a test file, Amazon Q populates a comment with the suggested tests.

## Additional supported features

In addition, these features are available on GitLab Duo with Amazon Q.

| Feature                                                                                                                                | GitLab version |
|----------------------------------------------------------------------------------------------------------------------------------------|----------------|
| [GitLab Duo Chat](../../user/gitlab_duo_chat/_index.md)                                                                                | GitLab 17.11 and later |
| [Code Suggestions](../../user/project/repository/code_suggestions/_index.md)                                                           | GitLab 17.11 and later |
| [Code Explanation](../../user/project/repository/code_explain.md)                                                                      | GitLab 17.11 and later |
| [Test Generation](../../user/gitlab_duo_chat/examples.md#write-tests-in-the-ide)                                                       | GitLab 17.11 and later |
| [Refactor Code](../../user/gitlab_duo_chat/examples.md#refactor-code-in-the-ide)                                                       | GitLab 17.11 and later |
| [Fix Code](../../user/gitlab_duo_chat/examples.md#fix-code-in-the-ide)                                                                 | GitLab 17.11 and later |
| [Root Cause Analysis](../../user/gitlab_duo_chat/examples.md#troubleshoot-failed-cicd-jobs-with-root-cause-analysis)                   | GitLab 17.11 and later |
| [Discussion Summary](../../user/discussions/_index.md#summarize-issue-discussions-with-duo-chat)                                       | GitLab 17.11 and later |
| [Vulnerability Explanation](../../user/application_security/vulnerabilities/_index.md#explaining-a-vulnerability)                      | GitLab 17.11 and later |
| [Vulnerability Resolution](../../user/application_security/vulnerabilities/_index.md#vulnerability-resolution)                         | GitLab 17.11 and later |

## Related topics

- [Set up GitLab Duo with Amazon Q](setup.md)
- [GitLab Duo authentication and authorization](../gitlab_duo/security.md)
