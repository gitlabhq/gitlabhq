---
stage: None - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
group: Unassigned - Facilitated functionality, see https://handbook.gitlab.com/handbook/product/categories/#facilitated-functionality
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
gitlab_dedicated: no
title: Health check
description: Perform health, liveness, and readiness checks.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

GitLab provides liveness and readiness probes to indicate service health and
reachability to required services. These probes report on the status of the
database connection, Redis connection, and access to the file system. These
endpoints [can be provided to schedulers like Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) to hold
traffic until the system is ready or restart the container as needed.

Health check endpoints are typically used for load balancers
and other Kubernetes scheduling systems that need to determine
service availability before redirecting traffic.

You should not use these endpoints to determine effective uptime
on large Kubernetes deployments. Doing so can show false negatives
when pods are removed by autoscaling, node failure, or for
other normal and otherwise non-disruptive operational needs.

To determine uptime on large Kubernetes deployments, look at traffic
to the UI. This is properly balanced and scheduled, and therefore is
a better indicator of effective uptime. You can also monitor the sign-in
page `/users/sign_in` endpoint.

<!-- vale gitlab_base.Spelling = NO -->

On GitLab.com, tools such as [Pingdom](https://www.pingdom.com/) and
Apdex measurements are used to determine uptime.

<!-- vale gitlab_base.Spelling = YES -->

## IP allowlist

To access monitoring resources, the requesting client IP needs to be included in the allowlist.
For details, see [how to add IPs to the allowlist for the monitoring endpoints](ip_allowlist.md).

## Using the endpoints locally

With default allowlist settings, the probes can be accessed from localhost using the following URLs:

```plaintext
GET http://localhost/-/health
```

```plaintext
GET http://localhost/health_check
```

```plaintext
GET http://localhost/-/readiness
```

```plaintext
GET http://localhost/-/liveness
```

## Health

Checks whether the application server is running.
It does not verify the database or other services
are running. This endpoint circumvents Rails Controllers
and is implemented as additional middleware `BasicHealthCheck`
very early into the request processing lifecycle.

```plaintext
GET /-/health
```

Example request:

```shell
curl "https://gitlab.example.com/-/health"
```

Example response:

```plaintext
GitLab OK
```

## Comprehensive health check

{{< alert type="warning" >}}
**Do not use `/health_check` for load balancing or autoscaling.** This endpoint validates backend services (database, Redis) and will fail even when the application is functioning properly if these services are slow or unavailable. This can cause unnecessary removal of healthy application nodes from load balancers.
{{< /alert >}}

The `/health_check` endpoint performs comprehensive health checks including database connectivity, Redis availability, and other backend services. It's provided by the `health_check` gem and validates the entire application stack.

Use this endpoint for:

- Comprehensive application monitoring
- Backend service health validation
- Troubleshooting connectivity issues
- Monitoring dashboards and alerting

```plaintext
GET /health_check
GET /health_check/database
GET /health_check/cache
GET /health_check/migrations
```

Example request:

```shell
curl "https://gitlab.example.com/health_check"
```

Example response (success):

```plaintext
success
```

Example response (failure):

```plaintext
health_check failed: Unable to connect to database
```

Available checks:

- `database` - Database connectivity
- `migrations` - Database migration status
- `cache` - Redis cache connectivity
- `geo` (EE only) - Geo replication status

## Readiness

The readiness probe checks whether the GitLab instance is ready
to accept traffic via Rails Controllers. The check by default
does validate only instance-checks.

If the `all=1` parameter is specified, the check also validates
the dependent services (Database, Redis, Gitaly etc.)
and gives a status for each.

```plaintext
GET /-/readiness
GET /-/readiness?all=1
```

Example request:

```shell
curl "https://gitlab.example.com/-/readiness"
```

Example response:

```json
{
   "master_check":[{
      "status":"failed",
      "message": "unexpected Master check result: false"
   }],
   ...
}
```

On failure, the endpoint returns a `503` HTTP status code.

This check is being exempt from Rack Attack.

## Liveness

{{< alert type="warning" >}}

In GitLab [12.4](https://about.gitlab.com/upcoming-releases/)
the response body of the Liveness check was changed
to match the example below.

{{< /alert >}}

Checks whether the application server is running.
This probe is used to know if Rails Controllers
are not deadlocked due to a multi-threading.

```plaintext
GET /-/liveness
```

Example request:

```shell
curl "https://gitlab.example.com/-/liveness"
```

Example response:

On success, the endpoint returns a `200` HTTP status code, and a response like below.

```json
{
   "status": "ok"
}
```

On failure, the endpoint returns a `503` HTTP status code.

This check is being exempt from Rack Attack.

## Sidekiq

Learn how to configure the [Sidekiq health checks](../sidekiq/sidekiq_health_check.md).
