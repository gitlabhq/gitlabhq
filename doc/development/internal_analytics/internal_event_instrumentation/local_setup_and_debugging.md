---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# Local setup and debugging

Internal events are using a tool called Snowplow under the hood. To develop and test internal events, there are several tools related to Snowplow to test frontend and backend events:

| Testing Tool                                 | Frontend Tracking  | Backend Tracking    | Local Development Environment | Production Environment | Production Environment |
|----------------------------------------------|--------------------|---------------------|-------------------------------|------------------------|------------------------|
| Snowplow Analytics Debugger Chrome Extension | Yes | No | Yes            | Yes     | Yes     |
| Snowplow Micro                               | Yes | Yes  | Yes            | No    | No    |

For local development you will have to either [setup a local event collector](#setup-local-event-collector) or [configure a remote event collector](#configure-a-remote-event-collector).
We recommend using the local setup together with the [internal events monitor](#internal-events-monitor) when actively developing new events.

## Setup local event collector

By default, self-managed instances do not collect event data via Snowplow. We can use [Snowplow Micro](https://docs.snowplow.io/docs/testing-debugging/snowplow-micro/what-is-micro/), a Docker based Snowplow collector, to test events locally:

1. Ensure [Docker is installed and working](https://www.docker.com/get-started/).

1. Enable Snowplow Micro:

   ```shell
   gdk config set snowplow_micro.enabled true
   ```

1. Optional. Snowplow Micro runs on port `9091` by default, you can change to `9092` by running:

   ```shell
   gdk config set snowplow_micro.port 9092
   ```

1. Regenerate your Procfile and YAML config by reconfiguring GDK:

   ```shell
   gdk reconfigure
   ```

1. Restart the GDK:

   ```shell
   gdk restart
   ```

1. You can now see all events being sent by your local instance in the [Snowplow Micro UI](http://localhost:9091/micro/ui) and can filter for specific events.

### Introduction to Snowplow Micro UI and API

<div class="video-fallback">
  Watch the video about <a href="https://www.youtube.com/watch?v=netZ0TogNcA">Snowplow Micro</a>
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/netZ0TogNcA" frameborder="0" allowfullscreen> </iframe>
</figure>

## Configure a remote event collector

On GitLab.com events are sent to a collector configured by GitLab. By default, self-managed instances do not have a collector configured and do not collect data with Snowplow.

You can configure your self-managed GitLab instance to use a custom Snowplow collector.

1. On the left sidebar, at the bottom, select **Admin Area**.
1. Select **Settings > General**.
1. Expand **Snowplow**.
1. Select **Enable Snowplow tracking** and enter your Snowplow configuration information. For example:

   | Name               | Value                         |
   |--------------------|-------------------------------|
   | Collector hostname | `your-snowplow-collector.net` |
   | App ID             | `gitlab`                      |
   | Cookie domain      | `.your-gitlab-instance.com`   |

1. Select **Save changes**.

## Internal Events Monitor

<div class="video-fallback">
  Watch the demo video about the <a href="https://www.youtube.com/watch?v=R7vT-VEzZOI">Internal Events Tracking Monitor</a>
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/R7vT-VEzZOI" frameborder="0" allowfullscreen> </iframe>
</figure>

To understand how events are triggered and metrics are updated while you use the Rails app locally or `rails console`,
you can use the monitor.

Start the monitor and list one or more events that you would like to monitor. In this example we would like to monitor `i_code_review_user_create_mr`.

```shell
rails runner scripts/internal_events/monitor.rb i_code_review_user_create_mr
```

The monitor shows two tables. The top table lists all the metrics that are defined on the `i_code_review_user_create_mr` event.
The second right-most column shows the value of each metric when the monitor was started and the right most column shows the current value of each metric.
The bottom table has a list selected properties of all Snowplow events that matches the event name.

If a new `i_code_review_user_create_mr` event is fired, the metrics values will get updated and a new event will appear in the `SNOWPLOW EVENTS` table.

The monitor looks like below.

```plaintext
Updated at 2023-10-11 10:17:59 UTC
Monitored events: i_code_review_user_create_mr

+--------------------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                          RELEVANT METRICS                                                                          |
+-----------------------------------------------------------------------------+------------------------------+-----------------------+---------------+---------------+
| Key Path                                                                    | Monitored Events             | Instrumentation Class | Initial Value | Current Value |
+-----------------------------------------------------------------------------+------------------------------+-----------------------+---------------+---------------+
| counts_monthly.aggregated_metrics.code_review_category_monthly_active_users | i_code_review_user_create_mr | AggregatedMetric      | 13            | 14            |
| counts_monthly.aggregated_metrics.code_review_group_monthly_active_users    | i_code_review_user_create_mr | AggregatedMetric      | 13            | 14            |
| counts_weekly.aggregated_metrics.code_review_category_monthly_active_users  | i_code_review_user_create_mr | AggregatedMetric      | 0             | 1             |
| counts_weekly.aggregated_metrics.code_review_group_monthly_active_users     | i_code_review_user_create_mr | AggregatedMetric      | 0             | 1             |
| redis_hll_counters.code_review.i_code_review_user_create_mr_monthly         | i_code_review_user_create_mr | RedisHLLMetric        | 8             | 9             |
| redis_hll_counters.code_review.i_code_review_user_create_mr_weekly          | i_code_review_user_create_mr | RedisHLLMetric        | 0             | 1             |
+-----------------------------------------------------------------------------+------------------------------+-----------------------+---------------+---------------+
+---------------------------------------------------------------------------------------------------------+
|                                             SNOWPLOW EVENTS                                             |
+------------------------------+--------------------------+---------+--------------+------------+---------+
| Event Name                   | Collector Timestamp      | user_id | namespace_id | project_id | plan    |
+------------------------------+--------------------------+---------+--------------+------------+---------+
| i_code_review_user_create_mr | 2023-10-11T10:17:15.504Z | 29      | 93           |            | default |
+------------------------------+--------------------------+---------+--------------+------------+---------+
```

## Snowplow Analytics Debugger Chrome Extension

[Snowplow Analytics Debugger](https://chrome.google.com/webstore/detail/snowplow-analytics-debugg/jbnlcgeengmijcghameodeaenefieedm) is a browser extension for testing frontend events.
It works in production, staging, and local development environments. It is especially suited to verifying correct events are getting sent in a deployed environment.

1. Install the [Snowplow Analytics Debugger](https://chrome.google.com/webstore/detail/snowplow-analytics-debugg/jbnlcgeengmijcghameodeaenefieedm) Chrome browser extension.
1. Open Chrome DevTools to the Snowplow Debugger tab.
1. Any event triggered on a GitLab page should appear in the Snowplow Debugger tab.
