---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Monitor application performance and troubleshoot performance issues.
ignore_in_report: true
title: Show CI/CD pipeline telemetry for Observability
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

When enabled, GitLab Observability automatically instruments your CI/CD pipelines,
providing visibility into pipeline performance, job durations, and execution flow without any code changes.

- Visibility into which jobs are slowing down your pipelines.
- How pipeline performance changes over time.
- Bottlenecks in your deployment process.

## Enable pipeline instrumentation

To enable automatic pipeline instrumentation, add the `GITLAB_OBSERVABILITY_EXPORT` CI/CD variable to your project or group:

1. In the top bar, select **Search or go to** and find your project or group.
1. In the left sidebar, select **Settings** > **CI/CD**.
1. Expand **Variables**.
1. Select **Add variable**.
1. Configure the variable:
   - **Key**: `GITLAB_OBSERVABILITY_EXPORT`
   - **Value**: One or more of `traces`, `metrics`, `logs` (comma-separated for multiple values)
   - **Type**: Variable
   - **Environment scope**: All (or specific environments)
1. Select **Add variable**.

## Instrumentation types

The `GITLAB_OBSERVABILITY_EXPORT` variable accepts the following values:

- `traces`: Exports distributed traces showing pipeline execution flow, job dependencies, and timing
- `metrics`: Exports metrics about pipeline duration, job success rates, and resource usage
- `logs`: Exports structured logs from pipeline execution

You can enable multiple types by separating them with commas:

```plaintext
traces,metrics,logs
```

## How it works

Once the variable is set, GitLab automatically:

1. Captures pipeline execution data after each pipeline completes
1. Converts the data to OpenTelemetry format based on your configuration
1. Exports the telemetry data to your GitLab Observability instance
1. Makes the data available in your observability dashboards

No changes to your `.gitlab-ci.yml` file are required. The instrumentation happens automatically in the background.

## View pipeline telemetry

After running pipelines with instrumentation enabled:

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Observability** > **Services**.
1. Select your `gitlab-ci` service to view traces, metrics, and logs from your pipeline executions.

The CI/CD dashboard template from [GitLab Observability Templates](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/) provides pre-built visualizations for pipeline performance analysis.

## Related topics

- [Troubleshooting Observability](troubleshooting.md)
