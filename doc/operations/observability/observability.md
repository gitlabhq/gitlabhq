---
stage: none
group: Embody
info: This page is owned by <https://handbook.gitlab.com/handbook/engineering/embody-team/>
description: Monitor application performance and troubleshoot performance issues.
ignore_in_report: true
title: Observability
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/6) in GitLab 18.1 as an experiment available to all users.

{{< /history >}}

GitLab Observability provides distributed tracing, metrics, and logs, all in one platform.
No cardinality limits. No separate tool for your team to learn.

Use GitLab Observability to:

- Monitor application performance through distributed tracing across microservices.
- Correlate code changes with production issues.
- Instrument CI/CD pipelines automatically without code changes.
- Send high-cardinality metrics without limits by using OpenTelemetry standards.

GitLab Observability is an experimental feature that is actively evolving.
You can start sending traces, logs, and metrics now. To get familiar with the workflow,
try it on a non-critical service first, then expand usage as needed.

<i class="fa-youtube-play" aria-hidden="true"></i>
For a detailed overview, see [GitLab Observability (O11y) Introduction](https://www.youtube.com/watch?v=XI9ZruyNEgs).
<!-- Video published on 2025-06-18 -->

GitLab Observability is available and free for all tiers. [Share feedback or request features](#share-your-feedback).

## Get started

1. Set up Observability, either on [your GitLab Self-Managed instance](setup_self_managed.md), or on [GitLab.com](setup_gitlab_com.md).
1. Add your OTLP endpoint to [start sending telemetry](send.md), or [view CI/CD pipeline telemetry](ci_cd.md).
1. View your first trace.
1. Debug a slow request.

<div class="video-fallback">
  Watch: <a href="https://www.youtube.com/watch?v=lZtgor6chMs">GitLab Observability setup</a>.
</div>
<figure class="video-container">
  <iframe src="https://www.youtube-nocookie.com/embed/lZtgor6chMs" frameborder="0" allowfullscreen> </iframe>
</figure>
<!-- Video published on 2026-05-04 -->

## Real-world usage

GitLab Observability is being used by teams worldwide to monitor their applications and infrastructure.

<!-- TODO: Add usage demonstration video showing real debugging workflow
<i class="fa-youtube-play" aria-hidden="true"></i>
For a usage demonstration, see [How to Debug Production Issues with GitLab Observability](VIDEO_URL).
-->

Our users are actively monitoring their systems with GitLab Observability on GitLab.com (as of the week of April 21, 2026):

- More than 57 million traces processed daily.
- More than 3,000 services actively monitored.

## Key features

### Monitor performance, trace issues

Find and debug issues more quickly.

- Enhanced development workflow. Correlate code changes directly with application performance metrics to identify when deployments introduce issues.
- Streamlined incident response. See recent deployments, code changes, and the developers involved in one place.

When an issue occurs, view:

- The performance trace that shows the slow query.
- The merge request that introduced the change.
- The developer who can fix it.
- The deployment that rolled it out.

### Unified platform

Monitor application performance through a unified dashboard that combines:

- Distributed tracing. Follow requests across microservices to identify bottlenecks.
- Metrics. Track application and infrastructure performance over time.
- Logs. Correlate log entries with traces and metrics for complete context.

Centralized management provides:

- Simplified access management. New engineers automatically gain access to production observability data when they receive code repository access.
- No context switching. Access monitoring data without leaving GitLab.

### Developer-friendly integration

Send the same OpenTelemetry data to multiple backends while you evaluate GitLab Observability.

- Migrate from Datadog or New Relic. If you're using OpenTelemetry, just change your OTLP endpoint.
- No vendor lock-in. Use standard OpenTelemetry instrumentation libraries. Switch providers anytime by changing your OTLP endpoint.

### Fast setup and instrumentation

Most teams are seeing their first traces within 5-10 minutes of enabling the feature.

- Pre-built dashboards. Start with templates for common use cases.
- Automatic CI/CD instrumentation. Set one environment variable and GitLab automatically instruments your CI/CD pipelines.

### Cost-effective and scalable

- Free for all tiers. No per-seat, per-metric, or per-host charges. No limits on traces, metrics, or logs.
- No cardinality limits. Send high-cardinality metrics without cost concerns.
- Open source model. Contribute features and fixes directly.
- Predictable costs. No surprise bills from metric explosions.

### Compliance and audit trails

The integration creates comprehensive audit trails that link code changes to system behavior,
valuable for compliance requirements and post-incident analysis.

## Learn more

- [OpenTelemetry documentation](https://opentelemetry.io/docs/instrumentation/). Language-specific instrumentation guides.
- [GitLab Observability Templates](https://gitlab.com/gitlab-org/embody-team/experimental-observability/o11y-templates/). Pre-built dashboards and examples.
- [Proposed features](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues/8)

## Get help

- [Discord community](https://discord.com/channels/778180511088640070/1379585187909861546). Join the conversation with other users.
- [GitLab issues](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues). Report bugs or request features.
- [Troubleshooting information](troubleshooting.md).

## Share your feedback

GitLab Observability is enhanced based on user feedback. To provide feedback:

- Join the [Discord channel](https://discord.com/channels/778180511088640070/1379585187909861546).
- [Open an issue](https://gitlab.com/gitlab-org/embody-team/experimental-observability/gitlab_o11y/-/issues) to report bugs or request features.
