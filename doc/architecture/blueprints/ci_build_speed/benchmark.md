---
status: ongoing
creation-date: "2024-01-12"
authors: [ "@grzesiek" ]
coach: "@grzesiek"
approvers: [ "@gabrielengel_gl"]
---

# CI Build Speed Benchmarking Framework

In order to understand how GitLab CI performs in terms of CI build speed, we
plan to build CI Build Speed Benchmarking Framework.

## Benchmark

In order to run the benchmark, we will:

1. Install the benchmarking tool.
1. Start the tool.
1. Runs scenarios.
1. Report results back to GitLab data warehouse.

In the first iteration, we will focus on measuring the speed of GitLab CI, GitHub Actions, and CircleCI.

## Principles

There are a few design principles we should abide by:

1. Make it CI-platform agnostic. Can run on any Continuous Integration platform.
1. Do not depend on any specific technology that might not be available on some platforms.
1. Easy installation setup, not requiring many dependencies. Zero-dependency would be ideal.
1. Send results back to GitLab through an HTTP request, unless there is a better way.
1. Read as much data about the environment running a build and send details in the telemetry.

## Benchmarking: Client Side

The benchmarking tool should be able to measure every step of CI build
execution:

1. Time from build requested to scenario execution started.
1. Monotonic time to execute each of the steps of the scenario.
1. Thread time to execute each of the steps of the scenario.
1. Time required to report results back to GitLab.

Ideally the tool could collect this data in the
[Open Telemetry Tracing](https://opentelemetry.io/docs/specs/otel/trace/api/)
format.

### Go-based tool

One of the solutions that could meet the requirements / principles listed
above, could be a Go-based binary, which would be installed on different CI
platform using `wget` / `curl` or in a different convinient way. The benefits
of using the binary are:

1. Easy installation method, without the need to use containers.
1. Few external dependencies for a statically-linked binary.
1. Many libraries available, for tracing or HTTP / API integrations.
1. Multi-threaded execution mode that broadens benchmarking scope.
1. Expressive language that can make it easier to maintain the scenarios.

### Benchmarking: Server Side

## Pipelines scheduler

In order to run the benchmark a new build / pipeline / job will have to be
started on a continuous integration platform under test. Some platforms support
scheduled pipelines, but this could make it difficult to measure the build
start-up time. On alternative to consider during the implementation is to start
pipelines using API trigger endpoints. Most of the CI platforms support this
way of running pipelines, and we could pass the start-up time / pipeline
creation request time in an argument, that then will be consumed by the
benchmarking tool, and forwarded to the data warehouse along with the build
benchmark telemetry.

## Data warehouse

The server side, that will receive benchmarking telemetry, will eventually need
to forward the data to a data warehouse, in which we will be able to visualize
results, like Kibana or our Observability / Tracing tooling.

Before doing that, it could be advisable to persist the payload in object
storage, just in case we need to migrate historical entries to a different data
warehouse later on.
