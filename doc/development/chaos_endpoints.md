---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Generating chaos in a test GitLab instance

<!-- vale gitlab.Spelling = NO -->

As [Werner Vogels](https://twitter.com/Werner), the CTO at Amazon Web Services, famously put it, **Everything fails, all the time**.

<!-- vale gitlab.Spelling = NO -->

As a developer, it's as important to consider the failure modes in which your software may operate as much as normal operation. Doing so can mean the difference between a minor hiccup leading to a scattering of `500` errors experienced by a tiny fraction of users, and a full site outage that affects all users for an extended period.

To paraphrase [Tolstoy](https://en.wikipedia.org/wiki/Anna_Karenina_principle), _all happy servers are alike, but all failing servers are failing in their own way_. Luckily, there are ways we can attempt to simulate these failure modes, and the chaos endpoints are tools for assisting in this process.

Currently, there are four endpoints for simulating the following conditions:

- Slow requests.
- CPU-bound requests.
- Memory leaks.
- Unexpected process crashes.

## Enabling chaos endpoints

For obvious reasons, these endpoints are not enabled by default on `production`.
They are enabled by default on **development** environments.

WARNING:
It is required that you secure access to the chaos endpoints using a secret token.
You should not enable them in production unless you absolutely know what you're doing.

A secret token can be set through the `GITLAB_CHAOS_SECRET` environment variable.
For example, when using the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)
this can be done with the following command:

```shell
GITLAB_CHAOS_SECRET=secret gdk run
```

Replace `secret` with your own secret token.

## Invoking chaos

After you have enabled the chaos endpoints and restarted the application, you can start testing using the endpoints.

By default, when invoking a chaos endpoint, the web worker process which receives the request handles it. This means, for example, that if the Kill
operation is invoked, the Puma worker process handling the request is killed. To test these operations in Sidekiq, the `async` parameter on
each endpoint can be set to `true`. This runs the chaos process in a Sidekiq worker.

## Memory leaks

To simulate a memory leak in your application, use the `/-/chaos/leakmem` endpoint.

The memory is not retained after the request finishes. After the request has completed, the Ruby garbage collector attempts to recover the memory.

```plaintext
GET /-/chaos/leakmem
GET /-/chaos/leakmem?memory_mb=1024
GET /-/chaos/leakmem?memory_mb=1024&duration_s=50
GET /-/chaos/leakmem?memory_mb=1024&duration_s=50&async=true
```

| Attribute    | Type    | Required | Description                                                                          |
| ------------ | ------- | -------- | ------------------------------------------------------------------------------------ |
| `memory_mb`  | integer | no       | How much memory, in MB, should be leaked. Defaults to 100MB.                         |
| `duration_s` | integer | no       | Minimum duration_s, in seconds, that the memory should be retained. Defaults to 30s. |
| `async`      | boolean | no       | Set to true to leak memory in a Sidekiq background worker process                    |

```shell
curl "http://localhost:3000/-/chaos/leakmem?memory_mb=1024&duration_s=10" \
     --header 'X-Chaos-Secret: secret'
curl "http://localhost:3000/-/chaos/leakmem?memory_mb=1024&duration_s=10&token=secret"
```

## CPU spin

This endpoint attempts to fully utilise a single core, at 100%, for the given period.

Depending on your rack server setup, your request may timeout after a predetermined period (normally 60 seconds).

```plaintext
GET /-/chaos/cpu_spin
GET /-/chaos/cpu_spin?duration_s=50
GET /-/chaos/cpu_spin?duration_s=50&async=true
```

| Attribute    | Type    | Required | Description                                                           |
| ------------ | ------- | -------- | --------------------------------------------------------------------- |
| `duration_s` | integer | no       | Duration, in seconds, that the core is used. Defaults to 30s          |
| `async`      | boolean | no       | Set to true to consume CPU in a Sidekiq background worker process     |

```shell
curl "http://localhost:3000/-/chaos/cpu_spin?duration_s=60" \
     --header 'X-Chaos-Secret: secret'
curl "http://localhost:3000/-/chaos/cpu_spin?duration_s=60&token=secret"
```

## DB spin

This endpoint attempts to fully utilise a single core, and interleave it with DB request, for the given period.
This endpoint can be used to model yielding execution to another threads when running concurrently.

Depending on your rack server setup, your request may timeout after a predetermined period (normally 60 seconds).

```plaintext
GET /-/chaos/db_spin
GET /-/chaos/db_spin?duration_s=50
GET /-/chaos/db_spin?duration_s=50&async=true
```

| Attribute    | Type    | Required | Description                                                                 |
| ------------ | ------- | -------- | --------------------------------------------------------------------------- |
| `interval_s` | float   | no       | Interval, in seconds, for every DB request. Defaults to 1s                  |
| `duration_s` | integer | no       | Duration, in seconds, that the core is used. Defaults to 30s                |
| `async`      | boolean | no       | Set to true to perform the operation in a Sidekiq background worker process |

```shell
curl "http://localhost:3000/-/chaos/db_spin?interval_s=1&duration_s=60" \
     --header 'X-Chaos-Secret: secret'
curl "http://localhost:3000/-/chaos/db_spin?interval_s=1&duration_s=60&token=secret"
```

## Sleep

This endpoint is similar to the CPU Spin endpoint but simulates off-processor activity, such as network calls to backend services. It sleeps for a given `duration_s`.

As with the CPU Spin endpoint, this may lead to your request timing out if `duration_s` exceeds the configured limit.

```plaintext
GET /-/chaos/sleep
GET /-/chaos/sleep?duration_s=50
GET /-/chaos/sleep?duration_s=50&async=true
```

| Attribute    | Type    | Required | Description                                                            |
| ------------ | ------- | -------- | ---------------------------------------------------------------------- |
| `duration_s` | integer | no       | Duration, in seconds, that the request sleeps for. Defaults to 30s     |
| `async`      | boolean | no       | Set to true to sleep in a Sidekiq background worker process            |

```shell
curl "http://localhost:3000/-/chaos/sleep?duration_s=60" \
     --header 'X-Chaos-Secret: secret'
curl "http://localhost:3000/-/chaos/sleep?duration_s=60&token=secret"
```

## Kill

This endpoint simulates the unexpected death of a worker process using the `KILL` signal.

Because this endpoint uses the `KILL` signal, the process isn't given an
opportunity to clean up or shut down.

```plaintext
GET /-/chaos/kill
GET /-/chaos/kill?async=true
```

| Attribute    | Type    | Required | Description                                                            |
| ------------ | ------- | -------- | ---------------------------------------------------------------------- |
| `async`      | boolean | no       | Set to true to signal a Sidekiq background worker process              |

```shell
curl "http://localhost:3000/-/chaos/kill" --header 'X-Chaos-Secret: secret'
curl "http://localhost:3000/-/chaos/kill?token=secret"
```

## Quit

This endpoint simulates the unexpected death of a worker process using the `QUIT` signal.
Unlike `KILL`, the `QUIT` signal will also attempt to write a core dump.
See [core(5)](https://man7.org/linux/man-pages/man5/core.5.html) for more information.

```plaintext
GET /-/chaos/quit
GET /-/chaos/quit?async=true
```

| Attribute    | Type    | Required | Description                                                            |
| ------------ | ------- | -------- | ---------------------------------------------------------------------- |
| `async`      | boolean | no       | Set to true to signal a Sidekiq background worker process              |

```shell
curl "http://localhost:3000/-/chaos/quit" --header 'X-Chaos-Secret: secret'
curl "http://localhost:3000/-/chaos/quit?token=secret"
```

## Run garbage collector

This endpoint triggers a GC run on the worker handling the request and returns its worker ID
plus GC stats as JSON. This is mostly useful when running Puma in standalone mode, since
otherwise the worker handling the request will not be known upfront.

Endpoint:

```plaintext
POST /-/chaos/gc
```

Example request:

```shell
curl --request POST "http://localhost:3000/-/chaos/gc" \
     --header 'X-Chaos-Secret: secret'
curl --request POST "http://localhost:3000/-/chaos/gc?token=secret"
```

Example response:

```json
{
  "worker_id": "puma_1",
  "gc_stat": {
    "count": 94,
    "heap_allocated_pages": 9077,
    "heap_sorted_length": 9077,
    "heap_allocatable_pages": 0,
    "heap_available_slots": 3699720,
    "heap_live_slots": 2827510,
    "heap_free_slots": 872210,
    "heap_final_slots": 0,
    "heap_marked_slots": 2827509,
    "heap_eden_pages": 9077,
    "heap_tomb_pages": 0,
    "total_allocated_pages": 9077,
    "total_freed_pages": 0,
    "total_allocated_objects": 14229357,
    "total_freed_objects": 11401847,
    "malloc_increase_bytes": 8192,
    "malloc_increase_bytes_limit": 30949538,
    "minor_gc_count": 71,
    "major_gc_count": 23,
    "compact_count": 0,
    "remembered_wb_unprotected_objects": 41685,
    "remembered_wb_unprotected_objects_limit": 83370,
    "old_objects": 2617806,
    "old_objects_limit": 5235612,
    "oldmalloc_increase_bytes": 8192,
    "oldmalloc_increase_bytes_limit": 122713697
  }
}
```
