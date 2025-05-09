---
stage: Deploy
group: Environments
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: DevOps Research and Assessment (DORA) metrics charts
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD analytics page display metrics and charts for [DevOps Research and Assessment (DORA) metrics](dora_metrics.md).
The charts display the evolution of each DORA metric over time, for the last week, month, 90 days, or 180 days.
This information provides insights into the health of your organization.

## View CI/CD analytics

You can view CI/CD analytics for a group or project.

Prerequisites:

- To view DORA metrics, the group or project must have an environment in the [production deployment tier](../../ci/environments/_index.md#deployment-tier-of-environments).

### For a group

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
