---
status: ongoing
creation-date: "2024-01-12"
authors: [ "@grzesiek" ]
coach: "@grzesiek"
approvers: [ "@gabrielengel_gl"]
---

<!-- vale gitlab.FutureTense = NO -->

# CI/CD Build Speed

## Summary

GitLab CI is a Continuous Integration platform which is widely used to run a
variety of jobs, builds, pipelines. It was [integrated into GitLab in September 2015](https://about.gitlab.com/releases/2015/09/22/gitlab-8-0-released/)
and has become [one of the most beloved CI/CD solutions](https://about.gitlab.com/blog/2017/09/27/gitlab-leader-continuous-integration-forrester-wave/).

With years we've added a lot of new features and code to the GitLab CI
platform. In order to retain the "one of the most beloved solutions" status, we
also need keep attention to making it fast, reliable and secure. This design
doc is describing the path towards the former: making GitLab CI fast by
improving CI build speed.

## Goals

1. Establish a CI Speed Benchmark, used to compare GitLab CI to other platforms.
1. Build CI Benchmark Framework to measure the GitLab CI speed over the long term.
1. Describe next steps for improving GitLab CI Build Speed.

## Proposal

### CI Speed Benchmark

First, we plan to build a [CI Speed Benchmark](benchmark.md) solution, that
will allow us to run specific scenarios on various CI/CD platform and ingest
results into our data warehouse.

This will make it possible to define a baseline of the CI Build Speed for many
different scenarios and track the progress we, and other providers, are making
over time.

The core part of this goal is to define a set of scenarios that will allow us
to build a proxy metrics for build speed. For example, we could run following
scenarios:

1. Time to first byte of build log for `echo "Hello World"` build.
1. Time to result to perform a CPU-intensive cryptographic operation.
1. Time to result to perform a memory-intensive for a given amount of bytes.
1. Time to result to build a Linux kernel.

The scenarios should be idempotent and deterministic.

In the first iteration, we will only focus on the total job execution time, and not go into detail e.g. comparing specific startup times.

### CI Benchmark Framework

Once we define scenarios that we want to implement, we should build a
[CI Benchmark Framework](benchmark.md). The framework will be used to run
scenarios in a Continuous Integration environment, and to send the results back
to our data warehouse, for analysis and comparison.

The main principles behind design choices for the framework, are:

1. Make it CI-platform agnostic. Can run on any Continuous Integration platform.
1. Do not depend on any specific technology that might not be available on some platforms.
1. Easy installation setup, not requiring many dependencies. Zero-dependency would be ideal.
1. Send results back to GitLab through an HTTP request, unless there is a better way.

#### Improve CI Build Speed

Once we can measure CI Build Speed, improving it can be possible. We will
define the next steps for improving the speed once we have initial results.
