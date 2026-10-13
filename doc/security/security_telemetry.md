---
stage: Security
group: Security Operations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Understand the security telemetry GitLab produces, and how to collect it on GitLab.com, GitLab Self-Managed, and GitLab Dedicated.
title: Security telemetry
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Security telemetry is the data you collect from GitLab to detect and investigate security incidents.

The GitLab Security Operations team wrote these recommendations for administrators of GitLab Self-Managed and GitLab Dedicated instances, and owners of namespaces on GitLab.com. Use them to understand the kinds of security telemetry GitLab produces, what each one tells you, and what you can collect on your offering and subscription tier. They supplement the logging and monitoring processes defined by your organization, but don't replace them.

When a detection fires, follow [responding to security incidents](responding_to_security_incidents.md) to contain and remediate the incident.

> [!warning]
> Use these suggestions and recommendations at your own risk. Which telemetry is available depends on your offering, subscription tier, and configuration.

## Kinds of security telemetry

GitLab produces two main kinds of security telemetry. They answer different questions and are collected in different ways, so use both where you can.

[Audit events](../user/compliance/audit_events.md)
: Structured events that GitLab emits when a security-relevant action happens: a user signs in, a permission changes, a token is created, a setting is changed. Each event records who did it, what was affected, from which IP address, and when. Audit events answer the question "what did users do in GitLab?" GitLab defines several hundred [audit event types](../user/compliance/audit_event_types.md).

[Application logs](../administration/logs/_index.md)
: Log files written by the GitLab Rails application and the components around it: Workhorse, Gitaly, GitLab Shell, and Sidekiq. They record every HTTP request, Git operation, and background job. Much of this activity never becomes an audit event: failed and blocked requests, requests to endpoints that are not audited, the exact parameters of a request, and the internal steps GitLab took to handle it. Application logs answer the question "what happened inside GitLab?", and are the only source for detecting exploitation attempts against GitLab itself.

Besides these two, several GitLab features record security-relevant data of their own, such as CI/CD job logs and the credentials inventory. For more information, see [other sources of security data](#other-sources-of-security-data).

## What you can collect on your offering and tier

The following table shows the minimum tier you need for each way of collecting security telemetry, on each offering. GitLab Dedicated is available on Ultimate only, so everything in this table is available on GitLab Dedicated.

| Collection method | GitLab.com | GitLab Self-Managed | GitLab Dedicated |
|-------------------|------------|---------------------|------------------|
| View audit events in GitLab, or retrieve them with the API | Premium | Premium | Yes |
| Stream audit events to a security information and event management (SIEM) system or other destination | Ultimate | Ultimate | Yes |
| Collect application logs | Not available. GitLab operates and retains these logs. | All tiers | Yes |

In practice, this means:

- On Free, you can see your own sign-in events and review CI/CD job logs, but you cannot view group, project, or instance audit events. On GitLab Self-Managed, you can still collect application logs, which include a small number of audit events written to `audit_json.log`.
- On Premium, you can view and search audit events in GitLab, and retrieve them with the API, but you cannot stream them. You are not blind to what happens in GitLab, but detection and long-term retention are up to you.
- On Ultimate, you can stream audit events to your SIEM in near real time, and receive the streaming-only events that are never shown in GitLab.

## View audit events

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

On Premium and Ultimate, you can view audit events without any setup:

- In the GitLab UI, at the [group, project, and instance level](../administration/compliance/audit_event_reports.md). Instance-level audit events are available on GitLab Self-Managed and GitLab Dedicated.
- With the [Audit events API](../api/audit_events.md), which returns the same events as the UI.

On Free, the only audit events you can see are your own [sign-in events](../user/compliance/audit_events.md#sign-in-audit-events), in the **Authentication log** of your user profile.

Viewing audit events is enough for spot checks and for investigating a specific user or project after the fact. It is not enough for detection, for several reasons:

- Each query is limited to a 30-day window, and the UI does not search event details.
- Some event types are [streaming-only](#streaming-only-events) and are never shown in GitLab.
- You cannot alert on events, correlate them with other data, or control how long they are retained.

If you cannot stream audit events, you can retrieve them from the API on a schedule and load them into your log platform. This gives you a searchable copy and a basis for detections, although with a delay, and without the streaming-only events.

## Stream audit events

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Audit event streaming sends every audit event to a destination you control as soon as it happens, so your SIEM has a complete, near-real-time record. Streaming is the recommended way to collect audit events on every offering, and the only way to receive streaming-only events.

### Streaming-only events

Some audit event types are streaming-only: they are not saved in GitLab, and you receive them only if you have a streaming destination. Many of them record read access to sensitive data, which makes them especially useful for detection. Examples include:

| Streaming-only event | What it tells you |
|----------------------|-------------------|
| `repository_git_operation` | Who cloned, fetched, or pushed to a repository |
| `repository_file_accessed_api` and `repository_file_accessed_web` | Who read a file through the API or the web UI |
| `job_artifact_downloaded` | Who downloaded a CI/CD job artifact |
| `variable_viewed_api` and `variable_viewed_graphql` | Who read a CI/CD variable |
| `personal_access_token_used_from_unseen_ip` | A token was used from an IP address not seen before |
| `user_authenticated_using_job_token` | A CI/CD job token was used to authenticate |

This is not a complete list. For all streaming-only events, see the **Saved to database** column in the [available audit event types](../user/compliance/audit_event_types.md#available-audit-event-types) list.

### Set up streaming

Where you configure streaming depends on your offering:

| Offering | Who configures it | Scope | More information |
|----------|-------------------|-------|------------------|
| GitLab.com | Owner of a top-level group | The top-level group, its subgroups, and its projects | [Audit event streaming for top-level groups](../user/compliance/audit_event_streaming.md) |
| GitLab Self-Managed and GitLab Dedicated | Administrator | The whole instance. You can also configure it per top-level group for different destinations across your organization. | [Audit event streaming for instances](../administration/compliance/audit_event_streaming.md) |

Streaming supports three destination types: an HTTP endpoint, Google Cloud Logging, and Amazon S3. You can add several destinations and [filter each one by event type](../user/compliance/audit_event_streaming.md#update-event-filters).

When you design the receiving side:

- Expect occasional duplicate deliveries and deduplicate on the event `id`.
- On GitLab.com, allow traffic from the [GitLab.com IP range](../user/gitlab_com/_index.md#ip-range) at your destination.
- Treat the destination as sensitive. Streamed events contain the full event details.
- Check the [destination limits](../administration/instance_limits.md#audit-events-streaming-destination-limits) if you plan many destinations.

## Collect application logs

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Audit events tell you that an action happened. Application logs tell you how. They give you request-level detail that audit events summarize, and they record a large amount of security-relevant activity that has no audit event at all, such as failed requests, rate-limited requests, requests to unaudited endpoints, and the full parameters of each request. If you can collect application logs, collect them.

### Security-relevant logs

The following logs are the most relevant for security monitoring. Paths are relative to `/var/log/gitlab/` on Linux package installations. The [log system](../administration/logs/_index.md#accessing-logs-on-helm-chart-installations) documentation explains where to find the same logs on Helm chart installations.

| Log | What it records | Use it to detect |
|-----|-----------------|------------------|
| [`gitlab-rails/production_json.log`](../administration/logs/_index.md#production_jsonlog) | Every request handled by the web application: user, IP, path, status, parameters. | Suspicious sign-in flows, settings changes, exploitation attempts against web endpoints. |
| [`gitlab-rails/api_json.log`](../administration/logs/_index.md#api_jsonlog) | Every REST API request: user, IP, route, status, parameters. | Token abuse, bulk data access through the API, automation by a compromised account. |
| [`gitlab-rails/graphql_json.log`](../administration/logs/_index.md#graphql_jsonlog) | GraphQL queries and their complexity. | Enumeration and bulk data access through GraphQL. |
| [`gitlab-rails/auth_json.log`](../administration/logs/_index.md#auth_jsonlog) | Requests blocked by rate limits and protected-path rules. | Brute force and credential stuffing. |
| [`gitlab-rails/audit_json.log`](../administration/logs/_index.md#audit_jsonlog) | Audit events written to file. | A local copy of audit events, including on tiers that cannot stream. |
| [`gitlab-rails/application_json.log`](../administration/logs/_index.md#application_jsonlog) | Instance events such as user creation and project deletion. | Account and project lifecycle changes. |
| [`gitlab-shell/gitlab-shell.log`](../administration/logs/_index.md#gitlab-shelllog) | Git operations over SSH: user, project, command. | Repository cloning and pushing over SSH, including by deploy keys. |
| [`gitlab-workhorse/current`](../administration/logs/_index.md#workhorse-logs) | HTTP access log for all traffic, including Git over HTTPS and file downloads. | Repository cloning over HTTPS, artifact and export downloads, web scanning. |
| [`gitaly/current`](../administration/logs/_index.md#gitaly-logs) | Repository operations and Git hooks. | Unusual repository access patterns, hook failures. |
| [`sidekiq/current`](../administration/logs/_index.md#sidekiq-logs) | Background jobs: imports, exports, mirror updates, notifications. | Project exports and mirror configuration used for exfiltration. |

### Follow a request across logs

Every request GitLab handles gets a correlation ID, and the same ID appears in every log the request touches, from Workhorse to Rails to Gitaly to Sidekiq. When you find a suspicious entry in one log, search all logs for its correlation ID to reconstruct the full request. For more information, see [find relevant log entries with a correlation ID](../administration/logs/tracing_correlation_id.md).

### Ship application logs to your platform

On GitLab Self-Managed
: Ship the logs from each node to your log platform with the log shipper of your choice. GitLab rotates logs locally and eventually deletes old files, so ship them before rotation removes them. To adjust rotation, see [logging configuration](https://docs.gitlab.com/omnibus/settings/logs/). In multi-node deployments, make sure your platform aggregates logs from every node so that a correlation ID search covers the whole request.

On GitLab Dedicated
: GitLab delivers application and infrastructure logs to an Amazon S3 bucket in your AWS account and retains them for one year. Grant your log collector read access to the bucket in Switchboard, and if you need logs for longer than one year, copy them to your own storage. For the setup steps, see [application logs for GitLab Dedicated](../administration/dedicated/monitor.md).

## Other sources of security data

Besides audit events and application logs, several GitLab features record security-relevant data that you can review directly or pull into your detections. Most of them are available in the GitLab UI without any collection setup, and several are available on all tiers.

| Data source | Availability | What it shows |
|-------------|--------------|---------------|
| [Sign-in audit events](../user/compliance/audit_events.md#sign-in-audit-events) | All tiers | Successful sign-ins for a user, in the **Authentication log** of the user profile. The only audit events available on Free. |
| [CI/CD job logs](../ci/jobs/job_logs.md) | All tiers | Commands run, exposed secrets, and pipelines started by an unexpected user. For storage and retention, see [job logs administration](../administration/cicd/job_logs.md). |
| [Job token authentication log](../ci/jobs/ci_job_token.md#job-token-authentication-log) | All tiers | Projects that authenticated to a project with a CI/CD job token. |
| [Credentials inventory](../administration/credentials_inventory.md) | Ultimate | Personal, group, and project access tokens, SSH keys, and GPG keys that exist in your instance or top-level group, with scopes and expiry. |
| [Secret push protection](../user/application_security/secret_detection/secret_push_protection/_index.md) and [pipeline secret detection](../user/application_security/secret_detection/_index.md) | Secret push protection: Ultimate. Pipeline secret detection: All tiers. | Secrets that users attempt to push, or that are committed to a repository. |

<!-- Keep this table in sync with the detection data sources table on detecting_security_incidents.md. -->

## Next steps

After your telemetry reaches your SIEM or log platform:

- To decide which signals to monitor and to deploy the TLDR detection rules, see [build a detection capability](detecting_security_incidents.md#build-a-detection-capability).
- Confirm that the event types your detections rely on reach your platform, especially the streaming-only ones. If you collect audit events with the API instead of streaming, check which detections depend on events you do not receive.
- Define a retention period that meets your investigation and compliance needs. GitLab retains stored audit events indefinitely, but your streaming destination and log platform define what you can actually search.

## Related topics

- [Security incidents](security_incidents.md)
- [Secure GitLab](_index.md)
