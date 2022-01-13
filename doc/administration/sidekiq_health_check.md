---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Sidekiq Health Check **(FREE SELF)**

GitLab provides liveness and readiness probes to indicate service health and
reachability to the Sidekiq cluster. These endpoints
[can be provided to schedulers like Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
to hold traffic until the system is ready or restart the container as needed.

The health check server can be set up when [configuring Sidekiq](sidekiq.md).

## Readiness

The readiness probe checks whether the Sidekiq workers are ready to process jobs.

```plaintext
GET /readiness
```

Assuming you set up Sidekiq's address and port to be `localhost` and `8092` respectively,
here's an example request:

```shell
curl "http://localhost:8092/readiness"
```

On success, the endpoint returns a `200` HTTP status code, and a response like the following:

```json
{
   "status": "ok"
}
```

## Liveness

Checks whether the Sidekiq cluster is running.

```plaintext
GET /liveness
```

Assuming you set up Sidekiq's address and port to be `localhost` and `8092` respectively,
here's an example request:

```shell
curl "http://localhost:8092/liveness"
```

On success, the endpoint returns a `200` HTTP status code, and a response like the following:

```json
{
   "status": "ok"
}
```
