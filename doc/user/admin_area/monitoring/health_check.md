# Health Check

> [Introduced][ce-3888] in GitLab 8.8.

GitLab provides a health check endpoint for uptime monitoring on the `health_check` web
endpoint. The health check reports on the overall system status based on the status of
the database connection, the state of the database migrations, and the ability to write
and access the cache. This endpoint can be provided to uptime monitoring services like
[Pingdom][pingdom], [Nagios][nagios-health], and [NewRelic][newrelic-health].

## Access Token

An access token needs to be provided while accessing the health check endpoint. The current
accepted token can be found on the `admin/health_check` page of your GitLab instance.

![access token](img/health_check_token.png)

The access token can be passed as a URL parameter:

```
https://gitlab.example.com/health_check.json?token=ACCESS_TOKEN
```

or as an HTTP header:

```bash
curl --header "TOKEN: ACCESS_TOKEN" https://gitlab.example.com/health_check.json
```

## Using the Endpoint

Once you have the access token, health information can be retrieved as plain text, JSON,
or XML using the `health_check` endpoint:

- `https://gitlab.example.com/health_check?token=ACCESS_TOKEN`
- `https://gitlab.example.com/health_check.json?token=ACCESS_TOKEN`
- `https://gitlab.example.com/health_check.xml?token=ACCESS_TOKEN`

You can also ask for the status of specific services:

- `https://gitlab.example.com/health_check/cache.json?token=ACCESS_TOKEN`
- `https://gitlab.example.com/health_check/database.json?token=ACCESS_TOKEN`
- `https://gitlab.example.com/health_check/migrations.json?token=ACCESS_TOKEN`

For example, the JSON output of the following health check:

```bash
curl --header "TOKEN: ACCESS_TOKEN" https://gitlab.example.com/health_check.json
```

would be like:

```
{"healthy":true,"message":"success"}
```

## Status

On failure, the endpoint will return a `500` HTTP status code. On success, the endpoint
will return a valid successful HTTP status code, and a `success` message. Ideally your
uptime monitoring should look for the success message.

[ce-3888]: https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/3888
[pingdom]: https://www.pingdom.com
[nagios-health]: https://nagios-plugins.org/doc/man/check_http.html
[newrelic-health]: https://docs.newrelic.com/docs/alerts/alert-policies/downtime-alerts/availability-monitoring
