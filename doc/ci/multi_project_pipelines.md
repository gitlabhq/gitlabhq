# Multi-project pipelines **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/2121) in
[GitLab Premium 9.3](https://about.gitlab.com/2017/06/22/gitlab-9-3-released/#multi-project-pipeline-graphs).

When you set up [GitLab CI/CD](README.md) across multiple projects, you can visualize
the entire pipeline, including all cross-project interdependencies.

## Overview

GitLab CI/CD is a powerful continuous integration tool that works not only per project, but also across projects. When you
configure GitLab CI for your project, you can visualize the stages
of your [jobs](pipelines.md#jobs) on a [pipeline graph](pipelines.md#pipeline-graphs).

![Multi-project pipeline graph](img/multi_project_pipeline_graph.png)

In the Merge Request Widget, multi-project pipeline mini-graphs are displayed,
and when hovering or tapping (on touchscreen devices) they will expand and be shown adjacent to each other.

![Multi-project mini graph](img/multi_pipeline_mini_graph.gif)

Multi-project pipelines are useful for larger products that require cross-project interdependeices, such as those
adopting a [microservices architecture](https://about.gitlab.com/2016/08/16/trends-in-version-control-land-microservices/).

## Use cases

Let's assume you deploy your web app from different projects in GitLab:

- One for the free version, which has its own pipeline that builds and tests your app
- One for the paid version add-ons, which also pass through builds and tests
- One for the documentation, which also builds, tests, and deploys with an SSG

With Multi-Project Pipelines, you can visualize the entire pipeline, including all stages of builds and tests for the three projects.

## How it works

When you use the [`CI_JOB_TOKEN` to trigger pipelines](triggers/README.md#ci-job-token), GitLab
recognizes the source of the job token, and thus internally ties these pipelines
together, allowing you to visualize their relationships on pipeline graphs.

These relationships are displayed in the pipeline graph by showing inbound and
outbound connections for upstream and downstream pipeline dependencies.
