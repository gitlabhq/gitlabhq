---
type: reference
---

# Multi-project pipelines **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/2121) in
[GitLab Premium 9.3](https://about.gitlab.com/blog/2017/06/22/gitlab-9-3-released/#multi-project-pipeline-graphs).

When you set up [GitLab CI/CD](README.md) across multiple projects, you can visualize
the entire pipeline, including all cross-project inter-dependencies.

## Overview

GitLab CI/CD is a powerful continuous integration tool that works not only per project, but also across projects. When you
configure GitLab CI for your project, you can visualize the stages
of your [jobs](pipelines.md#configuring-pipelines) on a [pipeline graph](pipelines.md#visualizing-pipelines).

![Multi-project pipeline graph](img/multi_project_pipeline_graph.png)

In the Merge Request Widget, multi-project pipeline mini-graphs are displayed,
and when hovering or tapping (on touchscreen devices) they will expand and be shown adjacent to each other.

![Multi-project mini graph](img/multi_pipeline_mini_graph.gif)

Multi-project pipelines are useful for larger products that require cross-project inter-dependencies, such as those
adopting a [microservices architecture](https://about.gitlab.com/blog/2016/08/16/trends-in-version-control-land-microservices/).

For a demonstration of how cross-functional development teams can use cross-pipeline
triggering to trigger multiple pipelines for different microservices projects, see
[Cross-project Pipeline Triggering and Visualization](https://about.gitlab.com/handbook/marketing/product-marketing/demo/#cross-project-pipeline-triggering-and-visualization-may-2019---1110).

## Use cases

Let's assume you deploy your web app from different projects in GitLab:

- One for the free version, which has its own pipeline that builds and tests your app
- One for the paid version add-ons, which also pass through builds and tests
- One for the documentation, which also builds, tests, and deploys with an SSG

With Multi-Project Pipelines, you can visualize the entire pipeline, including all stages of builds and tests for the three projects.

## Triggering multi-project pipelines through API

When you use the [`CI_JOB_TOKEN` to trigger pipelines](triggers/README.md#ci-job-token), GitLab
recognizes the source of the job token, and thus internally ties these pipelines
together, allowing you to visualize their relationships on pipeline graphs.

These relationships are displayed in the pipeline graph by showing inbound and
outbound connections for upstream and downstream pipeline dependencies.

## Creating multi-project pipelines from `.gitlab-ci.yml`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/8997) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.8.

### Triggering a downstream pipeline using a bridge job

Before GitLab 11.8, it was necessary to implement a pipeline job that was
responsible for making the API request [to trigger a pipeline](#triggering-multi-project-pipelines-through-api)
in a different project.

In GitLab 11.8, GitLab provides a new CI/CD configuration syntax to make this
task easier, and avoid needing GitLab Runner for triggering cross-project
pipelines. The following illustrates configuring a bridge job:

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my/deployment
```

In the example above, as soon as `rspec` job succeeds in the `test` stage,
the `staging` bridge job is going to be started. The initial status of this
job will be `pending`. GitLab will create a downstream pipeline in the
`my/deployment` project and, as soon as the pipeline gets created, the
`staging` job will succeed. `my/deployment` is a full path to that project.

The user that created the upstream pipeline needs to have access rights to the
downstream project (`my/deployment` in this case). If a downstream project can
not be found, or a user does not have access rights to create pipeline there,
the `staging` job is going to be marked as _failed_.

CAUTION: **Caution:**
In the example, `staging` will be marked as succeeded as soon as a downstream pipeline
gets created. If you want to display the downstream pipeline's status instead, see
[Mirroring status from triggered pipeline](#mirroring-status-from-triggered-pipeline).

NOTE: **Note:**
Bridge jobs do not support every configuration entry that a user can use
in the case of regular jobs. Bridge jobs will not to be picked by a Runner,
thus there is no point in adding support for `script`, for example. If a user
tries to use unsupported configuration syntax, YAML validation will fail upon
pipeline creation.

### Specifying a downstream pipeline branch

It is possible to specify a branch name that a downstream pipeline will use:

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable-11-2
```

Use:

- The `project` keyword to specify the full path to a downstream project.
- The `branch` keyword to specify the name of a branch in the project specified by `project`.
  [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/issues/10126), variable expansion is
  supported.

GitLab will use a commit that is currently on the HEAD of the branch when
creating a downstream pipeline.

### Passing variables to a downstream pipeline

Sometimes you might want to pass variables to a downstream pipeline.
You can do that using the `variables` keyword, just like you would when
defining a regular job.

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my/deployment
```

The `ENVIRONMENT` variable will be passed to every job defined in a downstream
pipeline. It will be available as an environment variable when GitLab Runner picks a job.

In the following configuration, the `MY_VARIABLE` variable will be passed to the downstream pipeline
that is created when the `trigger-downstream` job is queued. This is because `trigger-downstream`
job inherits variables declared in global variables blocks, and then we pass these variables to a downstream pipeline.

```yaml
variables:
  MY_VARIABLE: my-value

trigger-downstream:
  variables:
    ENVIRONMENT: something
  trigger: my/project
```

You might want to pass some information about the upstream pipeline using, for
example, predefined variables. In order to do that, you can use interpolation
to pass any variable. For example:

```yaml
downstream-job:
  variables:
    UPSTREAM_BRANCH: $CI_COMMIT_REF_NAME
  trigger: my/project
```

In this scenario, the `UPSTREAM_BRANCH` variable with a value related to the
upstream pipeline will be passed to the `downstream-job` job, and will be available
within the context of all downstream builds.

NOTE: **Tip:**
Upstream pipelines take precedence over downstream ones. If there are two
variables with the same name defined in both upstream and downstream projects,
the ones defined in the upstream project will take precedence.

### Mirroring status from triggered pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab/issues/11238) in [GitLab Premium](https://about.gitlab.com/pricing/) 12.3.

You can mirror the pipeline status from the triggered pipeline to the source
bridge job by using `strategy: depend`. For example:

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: depend
```

### Mirroring status from upstream pipeline

You can mirror the pipeline status from an upstream pipeline to a bridge job by
using the `needs:pipeline` keyword. The latest pipeline status from master is
replicated to the bridge job.

Example:

```yaml
upstream_bridge:
  stage: test
  needs:
    pipeline: other/project
```

### Limitations

Because bridge jobs are a little different to regular jobs, it is not
possible to use exactly the same configuration syntax here, as one would
normally do when defining a regular job that will be picked by a runner.

Some features are not implemented yet. For example, support for environments.

[Configuration keywords](yaml/README.md) available for bridge jobs are:

- `trigger` (to define a downstream pipeline trigger)
- `stage`
- `allow_failure`
- [`rules`](yaml/README.md#rules)
- `only` and `except`
- `when` (only with `on_success`, `on_failure`, and `always` values)
- `extends`
