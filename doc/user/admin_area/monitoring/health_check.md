---
type: concepts, howto
---

# Health Check

> - Liveness and readiness probes were [introduced][ce-10416] in GitLab 9.1.
> - The `health_check` endpoint was [introduced][ce-3888] in GitLab 8.8 and was
>   deprecated in GitLab 9.1.
> - [Access token](#access-token-deprecated) has been deprecated in GitLab 9.4
>   in favor of [IP whitelist](#ip-whitelist).

GitLab provides liveness and readiness probes to indicate service health and
reachability to required services. These probes report on the status of the
database connection, Redis connection, and access to the filesystem. These
endpoints [can be provided to schedulers like Kubernetes][kubernetes] to hold
traffic until the system is ready or restart the container as needed.

## IP whitelist

To access monitoring resources, the requesting client IP needs to be included in a whitelist.
For details, see [how to add IPs to a whitelist for the monitoring endpoints](../../../administration/monitoring/ip_whitelist.md).

## Using the endpoints

With default whitelist settings, the probes can be accessed from localhost using the following URLs:

- `http://localhost/-/health`
- `http://localhost/-/readiness`
- `http://localhost/-/liveness`

The first endpoint, `health`, only checks whether the application server is running. It does not verify the database or other services are running. A successful response will return a 200 status code with the following message:

```text
GitLab OK
```

The readiness and liveness probes will provide a report of system health in JSON format.

`readiness` probe example output:

```json
{
   "queues_check" : {
      "status" : "ok"
   },
   "redis_check" : {
      "status" : "ok"
   },
   "shared_state_check" : {
      "status" : "ok"
   },
   "db_check" : {
      "status" : "ok"
   },
   "cache_check" : {
      "status" : "ok"
   }
}
```

`liveness` probe example output:

```json
{
   "cache_check" : {
      "status" : "ok"
   },
   "db_check" : {
      "status" : "ok"
   },
   "redis_check" : {
      "status" : "ok"
   },
   "queues_check" : {
      "status" : "ok"
   },
   "shared_state_check" : {
      "status" : "ok"
   }
}
```

## Status

On failure, the endpoint will return a `500` HTTP status code. On success, the endpoint
will return a valid successful HTTP status code, and a `success` message.

## Access token (Deprecated)

> NOTE: **Note:**
> Access token has been deprecated in GitLab 9.4 in favor of [IP whitelist](#ip-whitelist).

An access token needs to be provided while accessing the probe endpoints. The current
accepted token can be found under the **Admin area ➔ Monitoring ➔ Health check**
(`admin/health_check`) page of your GitLab instance.

![access token](img/health_check_token.png)

The access token can be passed as a URL parameter:

```text
https://gitlab.example.com/-/readiness?token=ACCESS_TOKEN
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

[ce-10416]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/10416
[ce-3888]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3888
[pingdom]: https://www.pingdom.com
[nagios-health]: https://nagios-plugins.org/doc/man/check_http.html
[newrelic-health]: https://docs.newrelic.com/docs/alerts/alert-policies/downtime-alerts/availability-monitoring
[kubernetes]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/
