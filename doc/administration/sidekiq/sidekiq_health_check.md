---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Sidekiq Health Check

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed

GitLab provides liveness and readiness probes to indicate service health and
reachability to the Sidekiq cluster. These endpoints
[can be provided to schedulers like Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)
to hold traffic until the system is ready or restart the container as needed.

The health check server can be set up when [configuring Sidekiq](index.md).

## Readiness

The readiness probe checks whether the Sidekiq workers are ready to process jobs.

```plaintext
GET /readiness
```

If the server is bound to `localhost:8092`, the process cluster can be probed for readiness as follows:

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

If the server is bound to `localhost:8092`, the process cluster can be probed for liveness as follows:

```shell
curl "http://localhost:8092/liveness"
```

On success, the endpoint returns a `200` HTTP status code, and a response like the following:

```json
{
   "status": "ok"
}
```
