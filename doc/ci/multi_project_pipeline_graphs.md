# Multi-project pipeline graphs **[PREMIUM]**

> [Introduced](https://gitlab.com/gitlab-org/gitlab-ee/issues/2121) in
[GitLab Premium 9.3](https://about.gitlab.com/2017/06/22/gitlab-9-3-released/#multi-project-pipeline-graphs).

When you set up [GitLab CI/CD](README.md) across multiple projects, you can visualize
the entire pipeline, including all multi-project stages.

## Overview

GitLab CI/CD is a powerful continuous integration tool built-in GitLab.
GitLab CI works not only per project, but also across projects. When you
configure GitLab CI for your project, you can visualize the stages
of your [jobs](pipelines.md#jobs) on a chart called [pipeline graph](pipelines.md#pipeline-graphs).

![Multi-project pipeline graph](img/multi_project_pipeline_graph.png)

In the Merge Request Widget, multi-project pipeline mini-graps are displayed,
and when hovering or clicking (mobile) they will expand and be shown next to each other.

![Multi-project mini graph](img/multi_pipeline_mini_graph.gif)

Multi-project pipeline graphs are useful for larger projects, especially those
adopting a [microservices architecture](https://about.gitlab.com/2016/08/16/trends-in-version-control-land-microservices/),
that often have a set of interdependent components which form the complete product.

## Use cases

Let's assume you deploy your web app from different projects in GitLab:

- One for the free version, which has its own pipeline that builds and tests your app
- One for the paid version add-ons, which also pass through builds and tests
- One for the documentation, which also builds, tests, and deploys with an SSG

With Multi-Project Pipeline Graphs, you can visualize the entire pipeline in a
beautiful and clear chart, including all stages of builds and tests for the three projects.

## How it works

Using the [`CI_JOB_TOKEN` when triggering pipelines](triggers/README.md#ci-job-token), GitLab
recognizes the source of the job token, and thus internally ties these pipelines
together which makes it easy to start visualizing their relationships.

Those relationships are displayed in the pipeline graph by showing inbound and
outbound connections for upstream and downstream pipeline dependencies.
