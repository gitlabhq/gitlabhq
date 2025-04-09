---
stage: Monitor
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Event data
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- Toggle [enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/510333) in GitLab 17.11.

{{< /history >}}

## Data tracking for product usage at event level

For more information about changes to product usage data collection, read the blog post
[More granular product usage insights for GitLab Self-Managed and Dedicated](https://about.gitlab.com/blog/2025/03/26/more-granular-product-usage-insights-for-gitlab-self-managed-and-dedicated/).

### Event data

Event data tracks interactions (or actions) within the GitLab platform.
These interactions or actions could be user initiated such as initiating CI/CD pipelines, merging a merge request, triggering a webhook, or creating an issue.
Actions can also result from background system processing like scheduled pipeline succeeding.
The focus of event data collection is on the users' actions and the metadata associated with those actions.

User IDs are pseudonymized to protect privacy, and GitLab does not undertake any processes to re-identify or associate the metrics with individual users.
Event data does not include source code or other customer-created content stored within GitLab.

For more information, see also:

- [Internal events payload samples](../../development/internal_analytics/internal_event_instrumentation/internal_events_payload.md)
- [Metrics dictionary](https://metrics.gitlab.com/?status=active) for a list of events and metrics
- [Customer product usage information](https://handbook.gitlab.com/handbook/legal/privacy/customer-product-usage-information/) for data privacy policy

### Benefits of event data

Event-level data enhances several benefits of Service Ping by offering more granular insights without identifying users.

- Proactive support: Granular data allows our Customer Success Managers (CSMs) and support teams to access more detailed information, enabling them to drill down and create custom metrics tailored to your organization's unique needs, rather than relying on more generic, aggregated metrics.
- Targeted guidance: Event-level data provides a deeper understanding of how features are used, helping us uncover opportunities for optimization and improvement. The depth of data allows us to offer more precise, actionable recommendations to help you maximize the value of GitLab and enhance your workflows.
- Anonymized benchmarking reports: Granular event data enables more accurate and relevant performance comparisons with similar organizations by focusing on detailed usage patterns, rather than just high-level aggregated data.

### Enable or disable event-level data collection

{{< alert type="note" >}}

If Snowplow tracking is enabled, it will be automatically disabled when you enable product usage tracking. Only one data collection method can be active at a time.

{{< /alert >}}

To enable or disable event-level data collection:

1. Sign in as a user with administrator access.
1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > Metrics and Profiling**.
1. Expand **Event tracking**.
1. To enable the setting, select the checkbox **Enable event tracking**. To disable the setting, clear the checkbox.
1. Select **Save changes**.
