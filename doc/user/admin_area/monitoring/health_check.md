---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: concepts, howto
---

# Health Check **(FREE SELF)**

> - Liveness and readiness probes were [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/10416) in GitLab 9.1.
> - The `health_check` endpoint was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/3888) in GitLab 8.8 and was
>   deprecated in GitLab 9.1.
> - [Access token](#access-token-deprecated) has been deprecated in GitLab 9.4
>   in favor of [IP whitelist](#ip-whitelist).

GitLab provides liveness and readiness probes to indicate service health and
reachability to required services. These probes report on the status of the
database connection, Redis connection, and access to the file system. These
endpoints [can be provided to schedulers like Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) to hold
traffic until the system is ready or restart the container as needed.

## IP whitelist

To access monitoring resources, the requesting client IP needs to be included in a whitelist.
For details, see [how to add IPs to a whitelist for the monitoring endpoints](../../../administration/monitoring/ip_whitelist.md).

## Using the endpoints locally

With default whitelist settings, the probes can be accessed from localhost using the following URLs:

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

This check does hit the database and Redis if authenticated via `token`.

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

## Access token (Deprecated)

NOTE:
Access token has been deprecated in GitLab 9.4 in favor of [IP whitelist](#ip-whitelist).

An access token needs to be provided while accessing the probe endpoints. You can
find the current accepted token in the user interface:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Monitoring > Health Check**. (`admin/health_check`)

![access token](img/health_check_token.png)

The access token can be passed as a URL parameter:

```plaintext
https://gitlab.example.com/-/readiness?token=ACCESS_TOKEN
```

NOTE:
In case the database or Redis service are inaccessible, the probe endpoints response is not guaranteed to be correct.
You should switch to [IP whitelist](#ip-whitelist) from deprecated access token to avoid it.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
