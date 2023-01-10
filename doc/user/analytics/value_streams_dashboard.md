---
stage: Plan
group: Optimize
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Value Streams Dashboard **(PREMIUM)**

> Introduced in GitLab 15.8 as a Closed [Beta](../../policy/alpha-beta-support.md#beta-features) feature.

You can leave feedback on dashboard bugs or functionality in [issue 381787](https://gitlab.com/gitlab-org/gitlab/-/issues/381787).

This feature is not ready for production use.

The Value Streams Dashboard is a customizable dashboard to enable decision-makers to identify trends, patterns, and opportunities for digital transformation improvements.
This page is a work in progress, and we're updating the information as we add more features.
For more information, see the [Value Stream Management category direction page](https://about.gitlab.com/direction/plan/value_stream_management/).

## Initial use case

Our initial use case is focused on providing the ability to compare software delivery metrics.
This comparison can help decision-makers understand whether projects and groups are improving.

The beta version of the Value Streams Dashboard includes the following metrics:

- [DORA metrics](dora_metrics.md)
- [Value Stream Analytics (VSA) - flow metrics](value_stream_analytics.md)

The Value Streams Dashboard allows you to:

- Aggregate data records from different APIs.
- Track software performance (DORA) and flow of value (VSA) across the organization.

## DevOps metrics comparison

The DevOps metrics comparison displays DORA4 and flow metrics for a group or project in the
month-to-date, last month, the month before, and the past 180 days.

This visualization helps you get a high-level custom view over multiple DevOps metrics and
understand whether they're improving month over month. You can compare the performance between
groups, projects, and teams at a glance. This visualization helps you identify the teams and projects
that are the largest value contributors, overperforming, or underperforming.

![DevOps metrics comparison](img/devops_metrics_comparison_v15_8.png)

You can also drill down the metrics for further analysis.
When you hover over a metric, a tooltip displays an explanation of the metric and a link to the related documentation page.

## Customize the dashboard widgets

You can customize the Value Streams Dashboard and configure what subgroups and projects to include in the page.

A view can display maximum four subgroups or projects.

To display multiple subgroups and projects, specify their path as a URL parameter.

For example, the parameter `query=gitlab-org/gitlab-foss,gitlab-org/gitlab,gitlab-org/gitlab-design,gitlab-org/gitlab-docs` displays three separate widgets, one each for the:

- `gitlab-org` group
- `gitlab-ui` project
- `gitlab-org/plan-stage` subgroup
