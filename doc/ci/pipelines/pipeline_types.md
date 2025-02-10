---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Types of pipelines
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Multiple types of pipelines can run in a project, including:

- Branch pipelines
- Tag pipelines
- Merge request pipelines
- Merged results pipelines
- Merge trains

These types of pipelines all appear on the **Pipelines** tab of a merge request.

## Branch pipeline

Your pipeline can run every time you commit changes to a branch.

This type of pipeline is called a *branch pipeline*.

This pipeline runs by default. No configuration is required.

Branch pipelines:

- Run when you push a new commit to a branch.
- Have access to [some predefined variables](../variables/predefined_variables.md).
- Have access to [protected variables](../variables/_index.md#protect-a-cicd-variable)
  and [protected runners](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)
  when the branch is a [protected branch](../../user/project/repository/branches/protected.md).

## Tag pipeline

A pipeline can run every time you create or push a new [tag](../../user/project/repository/tags/_index.md).

This type of pipeline is called a *tag pipeline*.

This pipeline runs by default. No configuration is required.

Tag pipelines:

- Run when you create/push a new tag to your repository.
- Have access to [some predefined variables](../variables/predefined_variables.md).
- Have access to [protected variables](../variables/_index.md#protect-a-cicd-variable)
  and [protected runners](../runners/configure_runners.md#prevent-runners-from-revealing-sensitive-information)
  when the tag is a [protected tag](../../user/project/protected_tags.md).

## Merge request pipeline

Instead of a branch pipeline, you can configure your pipeline to run every time you make changes to the
source branch in a merge request.

This type of pipeline is called a *merge request pipeline*.

Merge request pipelines do not run by default. You must configure
the jobs in the `.gitlab-ci.yml` file to run as merge request pipelines.

For more information, see [merge request pipelines](merge_request_pipelines.md).

## Merged results pipeline

> - The `merged results` label was [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/132975) in GitLab 16.5.

A *merged results pipeline* runs on the result of the source and target branches merged together.
It's a type of merge request pipeline.

These pipelines do not run by default. You must configure the jobs in the `.gitlab-ci.yml` file
to run as a merge request pipeline, and enable merged results pipelines.

These pipelines display a `merged results` label in pipeline lists.

For more information, see [merged results pipeline](merged_results_pipelines.md).

## Merge trains

In projects with frequent merges to the default branch, changes in different merge requests
might conflict with each other. Use *merge trains* to put merge requests in a queue.
Each merge request is compared to the other, earlier merge requests, to ensure they all work together.

Merge trains differ from merged results pipelines, because merged results pipelines
ensure the changes work with the content in the default branch,
but not content that others are merging at the same time.

These pipelines do not run by default. You must configure the jobs in the `.gitlab-ci.yml` file
to run as a merge request pipeline, enable merged results pipelines, and enable merge trains.

These pipelines display a `merge train` label in pipeline lists.

For more information, see [merge trains](merge_trains.md).
