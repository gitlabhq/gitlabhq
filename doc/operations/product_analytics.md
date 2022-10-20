---
stage: Analytics
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Product Analytics **(FREE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/225167) in GitLab 13.3 [with a flag](../administration/feature_flags.md) named `product_analytics`. Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, ask an administrator to [enable the feature flag](../administration/feature_flags.md) named `product_analytics`. On GitLab.com, this feature is not available. The feature is not ready for production use.

GitLab enables you to go from planning an application to getting feedback. You can use
Product Analytics to receive and analyze events sent from your application. This analysis
provides observability information and feedback on how people use your product.

Events are collected by a [Rails collector](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/36443) and
then processed with [Snowplow](https://github.com/snowplow/snowplow). Events are stored in a GitLab database.

## View Product Analytics

You can view the event data collected about your applications.

Prerequisite:

- You must have at least the Reporter role.

To access Product Analytics:

1. On the top bar, select **Main menu > Projects** and find your project.
1. On the left sidebar, select **Monitor > Product Analytics**.

The Product Analytics interface contains:

- An Events tab that shows the recent events and a total count.
- A Graph tab that shows graphs based on events of the last 30 days.
- A Test tab that sends a sample event payload.
- A Setup page containing the code to implement in your application.

## Rate limits

While Product Analytics is under development, it's rate-limited to
**100 events per minute** per project. This limit prevents the events table in the
database from growing too quickly.
