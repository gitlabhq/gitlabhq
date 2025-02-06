---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CI/CD analytics
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

Use the CI/CD analytics page to view pipeline success rates and duration, and the history of [DevOps Research and Assessment (DORA) metrics](dora_metrics.md) over time.

## Pipeline success and duration charts

CI/CD analytics shows the history of your pipeline successes and failures, as well as how long each pipeline
ran.

Pipeline statistics are gathered by collecting all available pipelines for the
project, regardless of status. The data available for each individual day is based
on when the pipeline was created.

The total pipeline calculation includes child
pipelines and pipelines that failed with an invalid YAML. To filter pipelines based on other attributes, use the [Pipelines API](../../api/pipelines.md#list-project-pipelines).

## DevOps Research and Assessment (DORA) metrics charts

DETAILS:
**Tier:** Ultimate

> - Time to restore service chart [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356959) in GitLab 15.1.

CI/CD analytics also display metrics and charts for DORA metrics.
The charts display the evolution of each DORA metric over time, for the last week, month, 90 days, or 180 days.
This information provides insights into the health of your organization.

## View CI/CD analytics

You can view CI/CD analytics for a group or project.

Prerequisites:

- To view DORA metrics, the group or project must have an environment in the [production deployment tier](../../ci/environments/_index.md#deployment-tier-of-environments).

### For a group

DETAILS:
**Tier:** Ultimate

To view CI/CD analytics for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Analyze > CI/CD analytics**.

The page displays metrics and charts for:

- Release statistics
- DORA metrics

### For a project

To view CI/CD analytics for a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > CI/CD analytics**.

The page displays metrics and charts for:

- Pipelines
- DORA metrics
- Project quality
