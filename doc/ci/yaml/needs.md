---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Make jobs start earlier with `needs`
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can use the [`needs`](_index.md#needs) keyword to create dependencies between jobs
in a pipeline. Jobs run as soon as their dependencies are met, regardless of the pipeline's `stages`
configuration. You can even configure a pipeline with no stages defined (effectively one large stage)
and jobs still run in the proper order. This pipeline structure is a kind of
[directed acyclic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph).

For example, you may have a specific tool or separate website that is built
as part of your main project. Using `needs`, you can specify dependencies between
these jobs and GitLab executes the jobs as soon as possible instead of waiting
for each stage to complete.

Unlike other solutions for CI/CD, GitLab does not require you to choose between staged
or stageless execution flow. You can implement a hybrid combination of staged and stageless
in a single pipeline, using only the `needs` keyword to enable the feature for any job.

Consider a monorepo as follows:

```plaintext
./service_a
./service_b
./service_c
./service_d
```

This project could have a pipeline organized into three stages:

| build     | test     | deploy |
|-----------|----------|--------|
| `build_a` | `test_a` | `deploy_a` |
| `build_b` | `test_b` | `deploy_b` |
| `build_c` | `test_c` | `deploy_c` |
| `build_d` | `test_d` | `deploy_d` |

You can improve job execution by using `needs` to relate the `a` jobs to each other
separately from the `b`, `c`, and `d` jobs. `build_a` could take a very long time to build,
but `test_b` doesn't need to wait, it can be configured to start as soon as `build_b` is finished,
which could be much faster.

If desired, `c` and `d` jobs can be left to run in stage sequence.

The `needs` keyword also works with the [`parallel`](_index.md#parallel) keyword,
giving you powerful options for parallelization in your pipeline.

## Use cases

You can use the [`needs`](_index.md#needs) keyword to define several different kinds of
dependencies between jobs in a CI/CD pipeline. You can set dependencies to fan in or out,
and even merge back together (diamond dependencies). These dependencies could be used for
pipelines that:

- Handle multi-platform builds.
- Have a complex web of dependencies like an operating system build.
- Have a deployment graph of independently deployable but related microservices.

Additionally, `needs` can help improve the overall speed of pipelines and provide fast feedback.
By creating dependencies that don't unnecessarily
block each other, your pipelines run as quickly as possible regardless of
pipeline stages, ensuring output (including errors) is available to developers
as quickly as possible.
