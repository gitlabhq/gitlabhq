---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Health check
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab Self-Managed

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
For details, see [how to add IPs to the allowlist for the monitoring endpoints](../monitoring/ip_allowlist.md).

## Using the endpoints locally

With default allowlist settings, the probes can be accessed from localhost using the following URLs:

```plaintext
GET http://localhost/-/health
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

WARNING:
In GitLab [12.4](https://about.gitlab.com/upcoming-releases/)
the response body of the Liveness check was changed
to match the example below.

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

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, for example `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
