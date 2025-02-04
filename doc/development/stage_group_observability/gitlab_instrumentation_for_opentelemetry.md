---
stage: Monitor
group: Platform Insights
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: GitLab instrumentation for OpenTelemetry
---

## Enable OpenTelemetry tracing, metrics, and logs in GDK development

NOTE:
Currently the default GDK environment is not set up by default to properly
collect and display OpenTelemetry data. Therefore, you should point the
`OTEL_EXPORTER_*_ENDPOINT` ENV vars to a GitLab project:

1. Which has an Ultimate license, and where you have
1. In which you have at least the Maintainer role
1. In which you have access to enable top-level group feature flags (or is under the `gitlab-org` or `gitlab-com` top-level groups which already have the flags enabled)

Once you have a project identified to use:

1. Note the ID of the project (from the three dots at upper right of main project page).
1. Note the ID of the top-level group which contains the project.
1. When setting the environment variables for the following steps, add them to `env.runit` in the root of the `gitlab-development-kit` folder.
1. Follow instructions to [configure distributed tracing for a project](../tracing.md), with the following custom settings:
   - For the `OTEL_EXPORTER_OTLP_TRACES_ENDPOINT` environment variable, use the following value:

     ```shell
     export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="https://<gitlab-host>/v3/<gitlab-top-level-group-id>/<gitlab-project-id>/ingest/traces"
     ```

1. Follow instructions to [configure distributed metrics for a project](../metrics.md), with the following custom settings:
   - For the `OTEL_EXPORTER_OTLP_METRICS_ENDPOINT` environment variable, use the following value:

     ```shell
     export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT="https://<gitlab-host>/v3/<gitlab-top-level-group-id>/<gitlab-project-id>/ingest/metrics"
     ```

1. Follow instructions to [configure distributed logs for a project](../logs.md), with the following custom settings:
   - For the `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT` environment variable, use the following value:

     ```shell
     export OTEL_EXPORTER_OTLP_LOGS_ENDPOINT="https://<gitlab-host>/v3/<gitlab-top-level-group-id>/<gitlab-project-id>/ingest/logs"
     ```

1. Also add the following to the `env.runit` file:

   ```shell
   # GitLab-specific flag to enable the Rails initializer to set up OpenTelemetry exporters
   export GITLAB_ENABLE_OTEL_EXPORTERS=true
   ```

1. `gdk restart`.
1. Navigate to your project, and follow the instructions in the above docs to enable and view the tracing, metrics, or logs.

## References

- [Distributed Tracing](../tracing.md)
- [Metrics](../metrics.md)
- [Logs](../logs.md)

## Related design documents

- [GitLab Observability in GitLab.com and GitLab Self-Managed](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/observability_for_self_managed/)
- [GitLab Observability - Metrics](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/observability_metrics/)
- [GitLab Observability - Logging](https://handbook.gitlab.com/handbook/engineering/architecture/design-documents/observability_logging/)
