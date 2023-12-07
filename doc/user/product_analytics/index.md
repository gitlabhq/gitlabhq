---
stage: Monitor
group: Product Analytics
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Product analytics **(ULTIMATE ALL EXPERIMENT)**

> - Introduced in GitLab 15.4 as an [Experiment](../../policy/experiment-beta-support.md#experiment) feature [with a flag](../../administration/feature_flags.md) named `cube_api_proxy`. Disabled by default.
> - `cube_api_proxy` revised to only reference the [Product Analytics API](../../api/product_analytics.md) in GitLab 15.6.
> - `cube_api_proxy` removed and replaced with `product_analytics_internal_preview` in GitLab 15.10.
> - `product_analytics_internal_preview` replaced with `product_analytics_dashboards` in GitLab 15.11.
> - Snowplow integration [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/398253) in GitLab 15.11 [with a flag](../../administration/feature_flags.md) named `product_analytics_snowplow_support`. Disabled by default.
> - Snowplow integration feature flag `product_analytics_snowplow_support` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/130228) in GitLab 16.4.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `product_analytics_dashboards`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

This page is a work in progress, and we're updating the information as we add more features.
For more information, see the [group direction page](https://about.gitlab.com/direction/monitor/product-analytics/).
To leave feedback about Product Analytics bugs or functionality:

- Comment on [issue 391970](https://gitlab.com/gitlab-org/gitlab/-/issues/391970).
- Create an issue with the `group::product analytics` label.

## How product analytics works

Product analytics uses several tools:

- [**Snowplow**](https://docs.snowplow.io/docs) - A developer-first engine for collecting behavioral data, and passing it through to ClickHouse.
- [**ClickHouse**](https://clickhouse.com/docs) - A database suited to store, query, and retrieve analytical data.
- [**Cube**](https://cube.dev/docs/) - A universal semantic layer that provides an API to run queries against the data stored in ClickHouse.

The following diagram illustrates the product analytics flow:

```mermaid
---
title: Product Analytics flow
---
flowchart TB
    subgraph Event collection
        A([SDK]) --Send user data--> B[Snowplow Collector]
        B --Pass data through--> C[Snowplow Enricher]
    end
    subgraph Data warehouse
        C --Transform and enrich data--> D([ClickHouse])
    end
    subgraph Data visualization with dashboards
        E([Dashboards]) --Generated from the YAML definition--> F[Panels/Visualizations]
        F --Request data--> G[Product Analytics API]
        G --Run Cube queries with pre-aggregations--> H[Cube]
        H --Get data from database--> D
        D --Return results--> H
        H --Transform data to be rendered--> G
        G --Return data--> F
    end
```

## Enable product analytics

> - Introduced in GitLab 15.6 behind the [feature flag](../../administration/feature_flags.md) named `cube_api_proxy`. Disabled by default.
> - Moved to be behind the [feature flag](../../administration/feature_flags.md) named `product_analytics_admin_settings` in GitLab 15.7. Disabled by default.
> - `cube_api_proxy` removed and replaced with `product_analytics_internal_preview` in GitLab 15.10.
> - `product_analytics_internal_preview` replaced with `product_analytics_dashboards` in GitLab 15.11.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, an administrator can [enable the feature flags](../../administration/feature_flags.md) named `product_analytics_dashboards`, `product_analytics_admin_settings`, and `combined_analytics_dashboards`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

To track events in your project applications on a self-managed instance,
you must enable and configure product analytics.

Prerequisites:

- You must be an administrator of a self-managed GitLab instance.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand the **Analytics** tab and find the **Product analytics** section.
1. Select **Enable product analytics** and enter the configuration values.
1. Select **Save changes**.

### Project-level settings

You can override the instance-level settings defined by the administrator on a per-project basis. This allows you to
have a different configured product analytics instance for your project.

Prerequisites:

- Product analytics must be enabled at the instance-level.
- You must have at least the Maintainer role for the project or group the project belongs to.
- The project must be in a group namespace.

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Analytics**.
1. Expand **Configure** and enter the configuration values.
1. Select **Save changes**.

## Onboard a GitLab project

Onboarding a GitLab project means preparing it to receive events that are used for product analytics.

To onboard a project:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Analyze > Analytics dashboards**.
1. Under **Product analytics**, select **Set up**.
1. Select **Set up product analytics**.
Your instance is being created, and the project onboarded.

### Onboard an internal project

GitLab team members can enable Product Analytics on their internal projects on GitLab.com (Ultimate) during the experiment phase.

1. Send a message to the Product Analytics team (`#g_analyze_product_analytics`) informing them of the repository to be enabled.
1. Using ChatOps, enable both the `product_analytics_dashboards` and `combined_analytics_dashboards`:

    ```plaintext
    /chatops run feature set product_analytics_dashboards true --project=FULLPATH_TO_PROJECT
    /chatops run feature set combined_analytics_dashboards true --project=FULLPATH_TO_PROJECT
    ```

## Instrument your application

To instrument code to collect data, use one or more of the existing SDKs:

- [Browser SDK](instrumentation/browser_sdk.md)
- [Ruby SDK](https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-rb)
- [Python SDK](https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-python)
- [Node SDK](https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-node)
- [.NET SDK](https://gitlab.com/gitlab-org/analytics-section/product-analytics/gl-application-sdk-dotnet)

## Product analytics dashboards

> - Introduced in GitLab 15.5 behind the [feature flag](../../administration/feature_flags.md) named `product_analytics_internal_preview`. Disabled by default.
> - `product_analytics_internal_preview` replaced with `product_analytics_dashboards` in GitLab 15.11.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available per project or for your entire instance, an administrator can [enable the feature flag](../../administration/feature_flags.md) named `product_analytics_dashboards`.
On GitLab.com, this feature is not available.
This feature is not ready for production use.

Product analytics dashboards are a subset of dashboards under [Analytics dashboards](../analytics/analytics_dashboards.md).

Specifically product analytics dashboards and visualizations make use of the `cube_analytics` data type.
The `cube_analytics` data type connects to the Cube instance defined when [product analytics was enabled](#enable-product-analytics).
All filters and queries are sent to the Cube instance and the returned data is processed by the
product analytics data source to be rendered by the appropriate visualizations.

### Filling missing data

- Introduced in GitLab 16.3 behind the [feature flag](../../administration/feature_flags.md) named `product_analytics_dashboards`. Disabled by default.

When [exporting data](#raw-data-export) or [viewing dashboards](../analytics/analytics_dashboards.md#view-project-dashboards),
if there is no data for a given day, the missing data is autofilled with `0`.

This approach has the following benefits:

- The visualization's day axis matches the selected date range, removing ambiguity about missing data.
- Data exports have rows for the entire date range, making data analysis easier.

However, this approach also has the following limitations:

- The `day` [granularity](https://cube.dev/docs/product/apis-integrations/rest-api/query-format) must be used.
  All other granularities are not supported at this time.
- It only fills a date range defined by the [`inDateRange`](https://cube.dev/docs/product/apis-integrations/rest-api/query-format#indaterange) filter.
  - The date selector in the UI already uses this filter.
- The filling of data ignores the query-defined limit. If you set a limit of 10 data points over 20 days, it
  returns 20 data points, with the missing data filled by `0`.

[Issue 417231](https://gitlab.com/gitlab-org/gitlab/-/issues/417231) proposes a solution to this limitation.

## Funnel analysis

Use funnel analysis to understand the flow of users through your application, and where
users drop out of a predefined flow (for example, a checkout process or ticket purchase).

Each product can also define an unlimited number of funnels.
Like dashboards, funnels are defined using the GitLab YAML schema, and stored in the `.gitlab/analytics/funnels/` directory of a project repository.

Funnel definitions must include the keys `name` and `seconds_to_convert`, and an array of `steps`.

| Key                  | Description                                              |
|----------------------|----------------------------------------------------------|
| `name`               | The name of the funnel.                                  |
| `seconds_to_convert` | The number of seconds a user has to complete the funnel. |
| `steps`              | An array of funnel steps.                                |

Each step must include the keys `name`, `target`, and `action`.

| Key      | Description                                                                              |
|----------|------------------------------------------------------------------------------------------|
| `name`   | The name of the step. This should be a unique slug.                                      |
| `action` | The action performed. (Only `pageview` is supported.)                          |
| `target` | The target of the step. (Because only `pageview` is supported, this should be a path.) |

### Example funnel definition

The following example defines a funnel that tracks users who completed a purchase within one hour by going through three target pages:

```yaml
name: completed_purchase
seconds_to_convert: 3600
steps:
  - name: view_page_1
    target: '/page1.html'
    action: 'pageview'
  - name: view_page_2
    target: '/page2.html'
    action: 'pageview'
  - name: view_page_3
    target: '/page3.html'
    action: 'pageview'
```

### Query a funnel

You can [query the funnel data with the REST API](../../api/product_analytics.md#send-query-request-to-cube).
To do this, you can use the example query body below, where you need to replace `FUNNEL_NAME` with your funnel's name.

NOTE:
The `afterDate` filter is not supported. Please use `beforeDate` or `inDateRange`.

```json
{
  "query": {
      "measures": [
        "FUNNEL_NAME.count"
      ],
      "order": {
        "completed_purchase.count": "desc"
      },
      "filters": [
        {
          "member": "FUNNEL_NAME.date",
          "operator": "beforeDate",
          "values": [
            "2023-02-01"
          ]
        }
      ],
      "dimensions": [
        "FUNNEL_NAME.step"
      ]
    }
}
```

## Raw data export

Exporting the raw event data from the underlying storage engine can help you debug and create datasets for data analysis.

Because Cube acts as an abstraction layer between the raw data and the API, the exported raw data has some caveats:

- Data is grouped by the selected dimensions. Therefore, the exported data might be incomplete, unless including both `utcTime` and `userAnonymousId`.
- Data is by default limited to 10,000 rows, but you can increase the limit to maximum 50,000 rows. If your dataset has more than 50,000 rows, you must paginate through the results by using the `limit` and `offset` parameters.
- Data is always returned in JSON format. If you need it in a different format, you need to convert the JSON to the required format using a scripting language of your choice.

[Issue 391683](https://gitlab.com/gitlab-org/gitlab/-/issues/391683) tracks efforts to implement a more scalable export solution.

### Export raw data with Cube queries

You can [query the raw data with the REST API](../../api/product_analytics.md#send-query-request-to-cube),
and convert the JSON output to any required format.

To export the raw data for a specific dimension, pass a list of dimensions to the `dimensions` key.
For example, the following query outputs the raw data for the attributes listed:

```json
POST /api/v4/projects/PROJECT_ID/product_analytics/request/load?queryType=multi

{
    "query":{
  "dimensions": [
    "TrackedEvents.docEncoding",
    "TrackedEvents.docHost",
    "TrackedEvents.docPath",
    "TrackedEvents.docSearch",
    "TrackedEvents.eventType",
    "TrackedEvents.localTzOffset",
    "TrackedEvents.pageTitle",
    "TrackedEvents.src",
    "TrackedEvents.utcTime",
    "TrackedEvents.vpSize"
  ],
  "order": {
    "TrackedEvents.apiKey": "asc"
  }
    }
}
```

If the request is successful, the returned JSON includes an array of rows of results.

## View product analytics usage quota

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/424153) in GitLab 16.6 with a [flag](../../administration/feature_flags.md) named `product_analytics_usage_quota`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/427838) in GitLab 16.7. Feature flag `product_analytics_usage_quota` removed.

Product analytics usage quota is calculated from the number of events received from instrumented applications.
The tab displays the monthly totals for the group, and a breakdown of usage per project. Current month shows events counted to date.

To view product analytics usage quota:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > Usage quota** and select the **Product analytics** tab.

The usage quota excludes projects that are not onboarded with product analytics.

## Troubleshooting

### No events are collected

Check your [instrumentation details](#enable-product-analytics),
and make sure product analytics is enabled and set up correctly.
