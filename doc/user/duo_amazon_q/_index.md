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

{{< /details >}}

{{< history >}}

- Introduced as [beta](../../policy/development_stages_support.md#beta) in GitLab 17.7 [with a flag](../../administration/feature_flags/_index.md) named `amazon_q_integration`. Disabled by default.
- Feature flag `amazon_q_integration` removed in GitLab 17.8.
- Generally available with additional GitLab Duo feature support in GitLab 17.11.

{{< /history >}}

{{< alert type="note" >}}

GitLab Duo with Amazon Q cannot be combined with other GitLab Duo add-ons.

{{< /alert >}}

At re:Invent 2024, Amazon announced the GitLab Duo with Amazon Q integration.
With this integration, you can automate tasks and increase productivity.

GitLab Duo with Amazon Q:

- Can perform a variety of tasks in issues and merge requests.
- [Includes many other GitLab Duo features](../gitlab_duo/feature_summary.md).

For a click-through demo, see [the GitLab Duo with Amazon Q Product Tour](https://gitlab.navattic.com/duo-with-q).
<!-- Demo published on 2025-04-23 -->

To get a subscription for GitLab Duo with Amazon Q, contact your Account Executive.

Alternatively, to request a trial,
[fill out this form](https://about.gitlab.com/partners/technology-partners/aws/#form).

## Set up GitLab Duo with Amazon Q

When you have a GitLab Duo with Amazon Q subscription and GitLab 17.11 or later, you can
[set up GitLab Duo with Amazon Q on your instance](setup.md).

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

[You can have Amazon Q review automatically](setup.md#enter-the-arn-in-gitlab-and-enable-amazon-q)
when you open or reopen a merge request, or you can manually start a review.

To manually start:

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

### Generate unit tests

Generate new unit tests for your code using Amazon Q.

#### From an issue

1. Create an issue.
1. Use one of the following options to request that tests be generated for your code:
   - In the issue description, describe your request and select **Save changes**.
   - In a comment, type `/q dev` and select **Comment**.

Amazon Q creates a merge request with the suggested tests.

#### From a merge request

1. Open your merge request.
1. On the **Changes** tab, leave an inline comment where you want to add tests. Include
as much detail as possible in your feedback, such as file name, class name and line number.
1. In the comment, type `/q dev` on a new line and select **Add comment now**.

Amazon Q updates the merge request with the suggested tests.

## Related topics

- [Set up GitLab Duo with Amazon Q](setup.md)
- [View the full list of GitLab Duo with Amazon Q features](../gitlab_duo/feature_summary.md).
- [GitLab Duo authentication and authorization](../gitlab_duo/security.md)
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo with Amazon Q - From idea to merge request](https://youtu.be/jxxzNst3jpo?si=QHO8JnPgMoFIllbL) <!-- Video published on 2025-04-17 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo with Amazon Q - Upgrade Java](https://www.youtube.com/watch?v=qGyzG9wTsEo) <!-- Video published on 2025-10-16 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo with Amazon Q - Code review optimization](https://youtu.be/4gFIgyFc02Q?si=S-jO2M2jcXnukuN_) <!-- Video published on 2025-05-20 -->
- <i class="fa fa-youtube-play youtube" aria-hidden="true"></i> [GitLab Duo with Amazon Q - Make code changes based on feedback](https://youtu.be/31E9X9BrK5s?si=v232hBDmlGpv6fqC) <!-- Video published on 2025-05-30 -->
