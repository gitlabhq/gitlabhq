---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
description: Learn how to use merge request pipelines in GitLab CI/CD to test changes efficiently, run targeted jobs, and improve code quality before merging.
title: Merge request pipelines
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can configure your pipeline to run every time you make changes to the
source branch in a merge request.

This type of pipeline, called a merge request pipeline, runs when you:

- Create a new merge request from a source branch that has one or more commits.
- Push a new commit to the source branch for a merge request.
- Go to the **Pipelines** tab in a merge request and select **Run pipeline**.

In addition, merge request pipelines:

- Have access to [more predefined variables](merge_request_pipelines.md#available-predefined-variables).
- Can [optionally access protected variables or runners](#control-access-to-protected-variables-and-runners).

These pipelines display a `merge request` label in pipeline lists.

Merge request pipelines run on the contents of the source branch only, ignoring the content
of the target branch. To run a pipeline that tests the result of merging the source
and target branches together, use merged results pipelines.

## Prerequisites

To use merge request pipelines:

- Your project's `.gitlab-ci.yml` file must be
  [configured with jobs that run in merge request pipelines](#add-jobs-to-merge-request-pipelines).
- You must have at least the Developer role for the
  source project to run a merge request pipeline.
- Your repository must be a GitLab repository, not an [external repository](../ci_cd_for_external_repos/_index.md).

## Add jobs to merge request pipelines

Use the [`rules`](../yaml/_index.md#rules) keyword to configure jobs to run in
merge request pipelines. For example:

```yaml
job1:
  script:
    - echo "This job runs in merge request pipelines"
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
```

You can also use the [`workflow: rules`](../yaml/_index.md#workflowrules) keyword
to configure the entire pipeline to run in merge request pipelines. For example:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == 'merge_request_event'

job1:
  script:
    - echo "This job runs in merge request pipelines"

job2:
  script:
    - echo "This job also runs in merge request pipelines"
```

For common `workflow` examples, see:

- [Switch between branch pipelines and merge request pipelines](../yaml/workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)
- [Git Flow with merge request pipelines](../yaml/workflow.md#git-flow-with-merge-request-pipelines)

To [use security scanning tools with merge request pipelines](../../user/application_security/detect/security_configuration.md#use-security-scanning-tools-with-merge-request-pipelines),
use the CI/CD variable `AST_ENABLE_MR_PIPELINES` or the `latest` template edition.

## Use with forked projects

External contributors who work in forks can't create pipelines in the parent project.

A merge request from a fork that is submitted to the parent project triggers a
pipeline that:

- Is created and runs in the fork (source) project, not the parent (target) project.
- Uses the fork project's CI/CD configuration, resources, and project CI/CD variables.

Pipelines for forks display with the **fork** badge in the parent project.

### Run pipelines in the parent project

Project members in the parent project can trigger a merge request pipeline
for a merge request submitted from a fork project. This pipeline:

- Is created and runs in the parent (target) project, not the fork (source) project.
- Uses the CI/CD configuration present in the fork project's branch.
- Uses the parent project's CI/CD settings, resources, and project CI/CD variables.
- Uses the permissions of the parent project member that triggers the pipeline.

Run pipelines in fork project MRs to ensure that the post-merge pipeline passes in
the parent project. Additionally, if you do not trust the fork project's runner,
running the pipeline in the parent project uses the parent project's trusted runners.

{{< alert type="warning" >}}

Fork merge requests can contain malicious code that tries to steal secrets in the parent project
when the pipeline runs, even before merge. As a reviewer, carefully check the changes
in the merge request before triggering the pipeline. Unless you trigger the pipeline
through the API or the [`/rebase` quick action](../../user/project/quick_actions.md#issues-merge-requests-and-epics),
GitLab shows a warning that you must accept before the pipeline runs. Otherwise, **no warning displays**.

{{< /alert >}}

Prerequisites:

- The parent project's `.gitlab-ci.yml` file must be configured to
  [run jobs in merge request pipelines](#prerequisites).
- You must be a member of the parent project with [permissions to run CI/CD pipelines](../../user/permissions.md#cicd).
  You might need additional permissions if the branch is protected.
- The fork project must be [visible](../../user/public_access.md) to the
  user running the pipeline. Otherwise, the **Pipelines** tab does not display
  in the merge request.

To use the UI to run a pipeline in the parent project for a merge request from a fork project:

1. In the merge request, go to the **Pipelines** tab.
1. Select **Run pipeline**. You must read and accept the warning, or the pipeline does not run.

### Prevent pipelines from fork projects

To prevent users from running new pipelines for fork projects in the parent project
use [the projects API](../../api/projects.md#edit-a-project) to disable the `ci_allow_fork_pipelines_to_run_in_parent_project`
setting.

{{< alert type="warning" >}}

Pipelines created before the setting was disabled are not affected and continue to run.
If you rerun a job in an older pipeline, the job uses the same context as when the
pipeline was originally created.

{{< /alert >}}

## Available predefined variables

When you use merge request pipelines, you can use:

- All the same [predefined variables](../variables/predefined_variables.md) that are
  available in branch pipelines.
- [Additional predefined variables](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)
  available only to jobs in merge request pipelines.

## Control access to protected variables and runners

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/188008) in GitLab 18.1

{{< /history >}}

You can control access to [protected CI/CD variables](../variables/_index.md#protect-a-cicd-variable)
and [protected runners](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)
from merge request pipelines.

Merge request pipelines can only access these protected resources if both the source and target branches
of the merge request are [protected](../../user/project/repository/branches/protected.md). Also, the user triggering the pipeline should have push/merge access to the target branch of the Merge Request. Merge request pipelines can only access these protected resources if both the source and target branches belong to the same project. Merge request pipelines from a fork of a repository cannot access these protected resources.

Prerequisites:

- You must have the Maintainer role in the project.

To control access to protected variables and runners:

- Go to **Settings** > **CI/CD**.
- Expand **Variables**
- Under **Access protected resources in merge request pipelines**, select or clear
  the **Allow merge request pipelines to access protected variables and runners** option.
