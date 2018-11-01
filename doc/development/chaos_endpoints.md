# Generating Chaos in a test GitLab instance

As [Werner Vogels](https://twitter.com/Werner), the CTO at Amazon Web Services, famously put it, **Everything fails, all the time**.

As a developer, it's as important to consider the failure modes in which your software will operate as much as normal operation. Doing so can mean the difference between a minor hiccup leading to a scattering of 500 errors experienced by a tiny fraction of users and a full site outage affect all users for an extended period.

To paraphrase [Tolstoy](https://en.wikipedia.org/wiki/Anna_Karenina_principle), _all happy servers are alike, but all failing servers are failing in their own way_. Luckily, there are ways we can attempt to simulate these failure modes, and the chaos endpoints are tools for assisting in this process.

Currently, there are four endpoints for simulating the following conditions: slow requests, cpu-bound requests, memory leaks and unexpected process crashes.

## Enabling Chaos Endpoints

For obvious reasons, these endpoints are not enabled by default. They can be enabled by setting the `GITLAB_ENABLE_CHAOS_ENDPOINTS` environment variable.

For example, if you're using the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit) this can be done with the following command:

```shell
GITLAB_ENABLE_CHAOS_ENDPOINTS=1 gdk run
```

### Securing the Chaos Endpoints

**It is highly recommended that you secure access to the Chaos endpoints using a secret token**. This is recommended when enabling these endpoints locally, and essential when running in a staging or other shared environment. _It goes without saying that you should not enable them in production unless you absolutely know what you're doing._

A secret can be set through the `GITLAB_CHAOS_SECRET` environment variable. For example, when using the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit) this can be done with the following command line:

```shell
GITLAB_ENABLE_CHAOS_ENDPOINTS=1 GITLAB_CHAOS_SECRET=secret gdk run
```

Replace `secret` with your own secret token.

## Invoking Chaos

Once you have enabled the chaos endpoints and restarted the application you can start testing using the endpoints.

### Memory Leaks

To simulate a memory leak in your application, use the `/-/chaos/leakmem` endpoint.

For example, if your GitLab instance is listening at `localhost:3000`, you could `curl` the endpoint as follows:

```shell
curl http://localhost:3000/-/chaos/leakmem?memory_mb=1024 --header 'X-Chaos-Secret: secret'
```

The `memory_mb` parameter tells the application how much memory it should leak.

Note: the memory is not retained after the request, so once its completed, the Ruby garbage collector will attempt to recover the memory.

### CPU Spin

This endpoint attempts to fully utilise a single core, at 100%, for the given period.

```shell
curl http://localhost:3000/-/chaos/cpuspin?duration_s=60 --header 'X-Chaos-Secret: secret'
```

The `duration_s` parameter will configure how long the core is utilised.

Depending on your rack server setup, your request may timeout after a predermined period (normally 60 seconds). If you're using Unicorn, this is done by killing the worker process.

### Sleep

This endpoint is similar to the CPU Spin endpoint but simulates off-processor activity, such backend services of IO. It will sleep for a given duration.

```shell
curl http://localhost:3000/-/chaos/sleep?duration_s=60 --header 'X-Chaos-Secret: secret'
```

The `duration_s` parameter will configure how long the request will sleep for.

As with the CPU Spin endpoint, this may lead to your request timing out if duration exceeds the configured limit.

### Kill

This endpoint will simulate the unexpected death of a worker process using a `kill` signal.

```shell
curl http://localhost:3000/-/chaos/kill --header 'X-Chaos-Secret: secret'
```

Note: since this endpoint uses the `KILL` signal, the worker is not given a chance to cleanup or shutdown.
