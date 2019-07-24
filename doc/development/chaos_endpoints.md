# Generating chaos in a test GitLab instance

As [Werner Vogels](https://twitter.com/Werner), the CTO at Amazon Web Services, famously put it, **Everything fails, all the time**.

As a developer, it's as important to consider the failure modes in which your software will operate as much as normal operation. Doing so can mean the difference between a minor hiccup leading to a scattering of `500` errors experienced by a tiny fraction of users and a full site outage that affects all users for an extended period.

To paraphrase [Tolstoy](https://en.wikipedia.org/wiki/Anna_Karenina_principle), _all happy servers are alike, but all failing servers are failing in their own way_. Luckily, there are ways we can attempt to simulate these failure modes, and the chaos endpoints are tools for assisting in this process.

Currently, there are four endpoints for simulating the following conditions:

- Slow requests.
- CPU-bound requests.
- Memory leaks.
- Unexpected process crashes.

## Enabling chaos endpoints

For obvious reasons, these endpoints are not enabled by default on `production`.
They are enabled by default on **development** environments.

DANGER: **Danger:**
It is required that you secure access to the chaos endpoints using a secret token.
You should not enable them in production unless you absolutely know what you're doing.

A secret token can be set through the `GITLAB_CHAOS_SECRET` environment variable.
For example, when using the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)
this can be done with the following command:

```bash
GITLAB_CHAOS_SECRET=secret gdk run
```

Replace `secret` with your own secret token.

## Invoking chaos

Once you have enabled the chaos endpoints and restarted the application, you can start testing using the endpoints.

By default, when invoking a chaos endpoint, the web worker process which receives the request will handle it. This means, for example, that if the Kill
operation is invoked, the Puma or Unicorn worker process handling the request will be killed. To test these operations in Sidekiq, the `async` parameter on
each endpoint can be set to `true`. This will run the chaos process in a Sidekiq worker.

## Memory leaks

To simulate a memory leak in your application, use the `/-/chaos/leakmem` endpoint.

NOTE: **Note:**
The memory is not retained after the request finishes. Once the request has completed, the Ruby garbage collector will attempt to recover the memory.

```
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

```bash
curl http://localhost:3000/-/chaos/leakmem?memory_mb=1024&duration_s=10 --header 'X-Chaos-Secret: secret'
curl http://localhost:3000/-/chaos/leakmem?memory_mb=1024&duration_s=10&token=secret
```

## CPU spin

This endpoint attempts to fully utilise a single core, at 100%, for the given period.

Depending on your rack server setup, your request may timeout after a predetermined period (normally 60 seconds).
If you're using Unicorn, this is done by killing the worker process.

```
GET /-/chaos/cpu_spin
GET /-/chaos/cpu_spin?duration_s=50
GET /-/chaos/cpu_spin?duration_s=50&async=true
```

| Attribute    | Type    | Required | Description                                                           |
| ------------ | ------- | -------- | --------------------------------------------------------------------- |
| `duration_s` | integer | no       | Duration, in seconds, that the core will be utilized. Defaults to 30s |
| `async`      | boolean | no       | Set to true to consume CPU in a Sidekiq background worker process     |

```bash
curl http://localhost:3000/-/chaos/cpu_spin?duration_s=60 --header 'X-Chaos-Secret: secret'
curl http://localhost:3000/-/chaos/cpu_spin?duration_s=60&token=secret
```

## DB spin

This endpoint attempts to fully utilise a single core, and interleave it with DB request, for the given period.
This endpoint can be used to model yielding execution to another threads when running concurrently.

Depending on your rack server setup, your request may timeout after a predetermined period (normally 60 seconds).
If you're using Unicorn, this is done by killing the worker process.

```
GET /-/chaos/db_spin
GET /-/chaos/db_spin?duration_s=50
GET /-/chaos/db_spin?duration_s=50&async=true
```

| Attribute    | Type    | Required | Description                                                                 |
| ------------ | ------- | -------- | --------------------------------------------------------------------------- |
| `interval_s` | float   | no       | Interval, in seconds, for every DB request. Defaults to 1s                  |
| `duration_s` | integer | no       | Duration, in seconds, that the core will be utilized. Defaults to 30s       |
| `async`      | boolean | no       | Set to true to perform the operation in a Sidekiq background worker process |

```bash
curl http://localhost:3000/-/chaos/db_spin?interval_s=1&duration_s=60 --header 'X-Chaos-Secret: secret'
curl http://localhost:3000/-/chaos/db_spin?interval_s=1&duration_s=60&token=secret
```

## Sleep

This endpoint is similar to the CPU Spin endpoint but simulates off-processor activity, such as network calls to backend services. It will sleep for a given duration_s.

As with the CPU Spin endpoint, this may lead to your request timing out if duration_s exceeds the configured limit.

```
GET /-/chaos/sleep
GET /-/chaos/sleep?duration_s=50
GET /-/chaos/sleep?duration_s=50&async=true
```

| Attribute    | Type    | Required | Description                                                            |
| ------------ | ------- | -------- | ---------------------------------------------------------------------- |
| `duration_s` | integer | no       | Duration, in seconds, that the request will sleep for. Defaults to 30s |
| `async`      | boolean | no       | Set to true to sleep in a Sidekiq background worker process            |

```bash
curl http://localhost:3000/-/chaos/sleep?duration_s=60 --header 'X-Chaos-Secret: secret'
curl http://localhost:3000/-/chaos/sleep?duration_s=60&token=secret
```

## Kill

This endpoint will simulate the unexpected death of a worker process using a `kill` signal.

NOTE: **Note:**
Since this endpoint uses the `KILL` signal, the worker is not given a chance to cleanup or shutdown.

```
GET /-/chaos/kill
GET /-/chaos/kill?async=true
```

| Attribute    | Type    | Required | Description                                                            |
| ------------ | ------- | -------- | ---------------------------------------------------------------------- |
| `async`      | boolean | no       | Set to true to kill a Sidekiq background worker process                |

```bash
curl http://localhost:3000/-/chaos/kill --header 'X-Chaos-Secret: secret'
curl http://localhost:3000/-/chaos/kill?token=secret
```
