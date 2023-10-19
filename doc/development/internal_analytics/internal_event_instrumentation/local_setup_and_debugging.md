---
stage: Analyze
group: Analytics Instrumentation
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Local setup and debugging

Internal events are using a tool called Snowplow under the hood. To develop and test internal events, there are several tools related to Snowplow to test frontend and backend events:

| Testing Tool                                 | Frontend Tracking  | Backend Tracking    | Local Development Environment | Production Environment | Production Environment |
|----------------------------------------------|--------------------|---------------------|-------------------------------|------------------------|------------------------|
| Snowplow Analytics Debugger Chrome Extension | Yes | No | Yes            | Yes     | Yes     |
| Snowplow Micro                               | Yes | Yes  | Yes            | No    | No    |

For local development you will have to either [setup a local event collector](#setup-local-event-collector) or [configure a remote event collector](#configure-a-remote-event-collector).
We recommend the local setup when actively developing new events.

## Setup local event collector

By default, self-managed instances do not collect event data via Snowplow. We can use [Snowplow Micro](https://docs.snowplow.io/docs/testing-debugging/snowplow-micro/what-is-micro/), a Docker based Snowplow collector, to test events locally:

1. Ensure [Docker is installed and working](https://www.docker.com/get-started).

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

## Configure a remote event collector

On GitLab.com events are sent to a collector configured by GitLab. By default, self-managed instances do not have a collector configured and do not collect data with Snowplow.

You can configure your self-managed GitLab instance to use a custom Snowplow collector.

1. On the left sidebar, select **Search or go to**.
1. Select **Admin Area**.
1. On the left sidebar, select **Settings > General**.
1. Expand **Snowplow**.
1. Select **Enable Snowplow tracking** and enter your Snowplow configuration information. For example:

   | Name               | Value                         |
   |--------------------|-------------------------------|
   | Collector hostname | `your-snowplow-collector.net` |
   | App ID             | `gitlab`                      |
   | Cookie domain      | `.your-gitlab-instance.com`   |

1. Select **Save changes**.

## Snowplow Analytics Debugger Chrome Extension

[Snowplow Analytics Debugger](https://chrome.google.com/webstore/detail/snowplow-analytics-debugg/jbnlcgeengmijcghameodeaenefieedm) is a browser extension for testing frontend events.
It works in production, staging, and local development environments. It is especially suited to verifying correct events are getting sent in a deployed environment.

1. Install the [Snowplow Analytics Debugger](https://chrome.google.com/webstore/detail/snowplow-analytics-debugg/jbnlcgeengmijcghameodeaenefieedm) Chrome browser extension.
1. Open Chrome DevTools to the Snowplow Debugger tab.
1. Any event triggered on a GitLab page should appear in the Snowplow Debugger tab.
