---
stage: Verify
group: Runner
info: >-
  To determine the technical writer assigned to the Stage/Group associated with
  this page, see
  https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---
# Runner Fleet Dashboard **(ULTIMATE EXPERIMENT)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/424495) in GitLab 16.6 behind several [feature flags](../integration/clickhouse.md#enable-feature-flags).

This feature is an [Experiment](../policy/experiment-beta-support.md).
To join the list of users testing this feature, contact us in
[epic 11180](https://gitlab.com/groups/gitlab-org/-/epics/11180).

GitLab administrators can use the Runner Fleet Dashboard to assess the health of your instance runners.
The Runner Fleet Dashboard shows:

- Recent CI errors related caused by runner infrastructure.
- Number of concurrent jobs executed on most busy runners.
- Histogram of job queue times (available only with ClickHouse).

There is a proposal to introduce [more features](#whats-next) to the Runner Fleet Dashboard.

![Runner Fleet Dashboard](img/runner_fleet_dashboard.png)

## View the Runner Fleet Dashboard

Prerequisites:

- You must be an administrator.

To view the runner fleet dashboard:

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Runners**.
1. Click **Fleet dashboard**.

Most of the dashboard works without any additional actions, with the
exception of **Wait time to pick a job** chart and [proposed features](#whats-next).
These features require setting up an additional infrastructure, described in this page.

To test the Runner Fleet Dashboard and gather feedback, we have launched an early adopters program
for some customers to try this feature.

## Requirements

To test the Runner Fleet Dashboard as part of the early adopters program, you must:

- Run GitLab 16.7 or above.
- Have an [Ultimate license](https://about.gitlab.com/pricing/).
- Be able to run [ClickHouse database](../integration/clickhouse.md). We recommend using [ClickHouse Cloud](https://clickhouse.cloud/).

## What's next

Support for usage and cost analysis are proposed in
[epic 11183](https://gitlab.com/groups/gitlab-org/-/epics/11183).

## Feedback

To help us improve the Runner Fleet Dashboard, you can provide feedback in
[issue 421737](https://gitlab.com/gitlab-org/gitlab/-/issues/421737).
In particular:

- How easy or difficult it was to setup GitLab to make the dashboard work.
- How useful you found the dashboard.
- What other information you would like to see on that dashboard.
- Any other related thoughts and ideas.
