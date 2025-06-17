---
stage: Monitor
group: Analytics Instrumentation
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/development/development_processes/#development-guidelines-review.
title: Internal Event Tracking
---

This page provides detailed guidelines on using the Internal Event Tracking system to instrument features on GitLab.

Currently Internal Event Tracking is consolidating the following systems:

- [Service Ping](../service_ping/_index.md)
- Snowplow
- AiTracking (Duo Chat) WIP

Internal Events is an unified interface to track events in GitLab. Each tracking call represents a user action and the
associated properties. Internal Events then provides underlying systems the properties they require for their specific
analytics needs.

Analytics systems summary:

| Function\System | Service Ping | Snowplow |
| --- | --- | --- |
| Primary function | Provide aggregated analytics data | Track raw events (user interactions with the service) |
| Data storage | Local instance (Redis, Postgres etc) | Snowflake |
| Data granularity | None (data is aggregated) | Per event |
| Extra parameters | None | Any amount of custom data |
| Receiving delay | Up to 1 week | A few minutes |
| Implementation | Utilises Internal Events, Database records, System Settings | Internal Events plus custom tracking context |

This page is a work in progress. If you have access to the GitLab Slack workspace, use the
`#g_monitor_analytics_instrumentation` channel for any questions or clarifications.

- [Quick start for internal event tracking](quick_start.md)
- [Migrating existing tracking to internal event tracking](migration.md)
- [Event definition guide](event_definition_guide.md)
- [Metric definition guide](metric_definition_guide.md)
- [Local setup and debugging](local_setup_and_debugging.md)
- [Internal Events CLI contribution guide](../cli_contribution_guidelines.md)
- [Internal Events Payload Samples](internal_events_payload.md)
- [Standard context fields description](standard_context_fields.md)
