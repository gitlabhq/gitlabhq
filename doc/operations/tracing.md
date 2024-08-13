---
stage: Monitor
group: Observability
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Distributed tracing

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com
**Status:** Beta

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/124966) in GitLab 16.2 [with a flag](../administration/feature_flags.md) named `observability_tracing`. Disabled by default. This feature is in [beta](../policy/experiment-beta-support.md#beta).
> - Feature flag [changed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/158786) in GitLab 17.3 to the `observability_features` [feature flag](../administration/feature_flags.md), disabled by default. The previous feature flag `observability_tracing` was removed.

FLAG:
The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use.

With distributed tracing, you can troubleshoot application performance issues by inspecting how a request moves through different services and systems, the timing of each operation, and any errors or logs as they occur. Tracing is particularly useful in the context of microservice applications, which group multiple independent services collaborating to fulfill user requests.

This feature is in [beta](../policy/experiment-beta-support.md). For more information, see the [group direction page](https://about.gitlab.com/direction/monitor/observability/). To leave feedback about tracing bugs or functionality, comment in the [feedback issue](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/2590) or open a [new issue](https://gitlab.com/gitlab-org/opstrace/opstrace/-/issues/new).

## Configure distributed tracing for a project

To configure distributed tracing:

1. [Create an access token and enable tracing.](#create-an-access-token)
1. [Configure your application to use the OpenTelemetry exporter.](#configure-your-application-to-use-the-opentelemetry-exporter)

### Create an access token

Prerequisites:

- You must have at least the Maintainer role for the project.

To enable tracing in a project, you must first create an access token:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > Access tokens**.
1. Create an access token with the following scopes: `read_api`, `read_observability`, `write_observability`.
1. Copy the value of the access token.

### Configure your application to use the OpenTelemetry exporter

Next, configure your application to send traces to GitLab.

To do this, set the following environment variables:

```shell
OTEL_EXPORTER = "otlphttp"
OTEL_EXPORTER_OTLP_TRACES_ENDPOINT = "https://observe.gitlab.com/v3/<namespace-id>/<gitlab-project-id>/ingest/traces"
OTEL_EXPORTER_OTLP_TRACES_HEADERS = "PRIVATE-TOKEN=<gitlab-access-token>"
```

Use the following values:

- `namespace-id`: The top-level namespace ID where your project is located.
- `gitlab-project-id`: The project ID.
- `gitlab-access-token`: The access token you [created previously](#create-an-access-token).

When your application is configured, run it, and the OpenTelemetry exporter attempts to send
traces to GitLab.

## View your traces

If your traces are exported successfully, you can see them in the project.

To view the list of traces:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Monitor > Traces**.

To see the details of a trace, select it from the list.

![list of traces](img/tracing_list_v16.11.png)

The trace details page and a list of spans are displayed.

![tracing details](img/tracing_details_v16_7.png)

To view the attributes for a single span, select it from the list.

![tracing drawer](img/tracing_drawer_v16_7.png)

## Tracing ingestion limits

Tracing ingests a maximum of 102,400 bytes per minute.
After the limit is exceeded, a `429 Too Many Requests` response is returned.

To request a limit increase to 1,048,576 bytes per minute, contact GitLab support.

## Data retention

GitLab has a retention limit of 30 days for all traces.
