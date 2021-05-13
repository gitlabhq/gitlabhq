---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Multi-project pipelines **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Free in 12.8.

You can set up [GitLab CI/CD](README.md) across multiple projects, so that a pipeline
in one project can trigger a pipeline in another project.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview see the [Multi-project pipelines demo](https://www.youtube.com/watch?v=g_PIwBM1J84).

GitLab CI/CD is a powerful continuous integration tool that works not only per project,
but also across projects with multi-project pipelines.

Multi-project pipelines are useful for larger products that require cross-project inter-dependencies, such as those
adopting a [microservices architecture](https://about.gitlab.com/blog/2016/08/16/trends-in-version-control-land-microservices/).

Cross-functional development teams can use cross-pipeline
triggering to trigger multiple pipelines for different microservices projects. Learn more
in the [Cross-project Pipeline Triggering and Visualization demo](https://about.gitlab.com/learn/)
at GitLab@learn, in the Continuous Integration (CI) section.

Additionally, it's possible to visualize the entire pipeline, including all cross-project
inter-dependencies. **(PREMIUM)**

## Use cases

Let's assume you deploy your web app from different projects in GitLab:

- One for the free version, which has its own pipeline that builds and tests your app
- One for the paid version add-ons, which also pass through builds and tests
- One for the documentation, which also builds, tests, and deploys with an SSG

With Multi-Project Pipelines you can visualize the entire pipeline, including all build and test stages for the three projects.

## Multi-project pipeline visualization **(PREMIUM)**

When you configure GitLab CI/CD for your project, you can visualize the stages of your
[jobs](pipelines/index.md#configure-a-pipeline) on a [pipeline graph](pipelines/index.md#visualize-pipelines).

![Multi-project pipeline graph](img/multi_project_pipeline_graph.png)

In the Merge Request Widget, multi-project pipeline mini-graphs are displayed,
and when hovering or tapping (on touchscreen devices) they expand and are shown adjacent to each other.

![Multi-project mini graph](img/multi_pipeline_mini_graph.gif)

## Triggering multi-project pipelines through API

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/31573) to GitLab Free in 12.4.

When you use the [`CI_JOB_TOKEN` to trigger pipelines](triggers/README.md#ci-job-token), GitLab
recognizes the source of the job token, and thus internally ties these pipelines
together, allowing you to visualize their relationships on pipeline graphs.

These relationships are displayed in the pipeline graph by showing inbound and
outbound connections for upstream and downstream pipeline dependencies.

When using:

- CI/CD Variables or [`rules`](yaml/README.md#rulesif) to control job behavior, the value of
  the [`$CI_PIPELINE_SOURCE` predefined variable](variables/predefined_variables.md) is
  `pipeline` for multi-project pipeline triggered through the API with `CI_JOB_TOKEN`.
- [`only/except`](yaml/README.md#only--except) to control job behavior, use the
  `pipelines` keyword.

## Creating multi-project pipelines from `.gitlab-ci.yml`

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Free in 12.8.

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

In the example above, as soon as the `rspec` job succeeds in the `test` stage,
the `staging` bridge job is started. The initial status of this
job is `pending`. GitLab then creates a downstream pipeline in the
`my/deployment` project and, as soon as the pipeline is created, the
`staging` job succeeds. `my/deployment` is a full path to that project.

The user that created the upstream pipeline needs to have access rights to the
downstream project (`my/deployment` in this case). If a downstream project is
not found, or a user does not have access rights to create a pipeline there,
the `staging` job is marked as _failed_.

When using:

- CI/CD variables or [`rules`](yaml/README.md#rulesif) to control job behavior, the value of
  the [`$CI_PIPELINE_SOURCE` predefined variable](variables/predefined_variables.md) is
  `pipeline` for multi-project pipelines triggered with a bridge job (using the
  [`trigger:`](yaml/README.md#trigger) keyword).
- [`only/except`](yaml/README.md#only--except) to control job behavior, use the
  `pipelines` keyword.

In the example, `staging` is marked as successful as soon as a downstream pipeline
gets created. If you want to display the downstream pipeline's status instead, see
[Mirroring status from triggered pipeline](#mirroring-status-from-triggered-pipeline).

NOTE:
Bridge jobs [do not support every configuration keyword](#limitations) that can be used
with other jobs. If a user tries to use unsupported configuration keywords, YAML
validation fails on pipeline creation.

### Specifying a downstream pipeline branch

It is possible to specify a branch name that a downstream pipeline uses:

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
  [From GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/10126), variable expansion is
  supported.

GitLab uses a commit that is on the head of the branch when
creating a downstream pipeline.

NOTE:
Pipelines triggered on a protected branch in a downstream project use the [permissions](../user/permissions.md)
of the user that ran the trigger job in the upstream project. If the user does not
have permission to run CI/CD pipelines against the protected branch, the pipeline fails. See
[pipeline security for protected branches](pipelines/index.md#pipeline-security-on-protected-branches).

### Passing CI/CD variables to a downstream pipeline

#### With the `variables` keyword

Sometimes you might want to pass CI/CD variables to a downstream pipeline.
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

The `ENVIRONMENT` variable is passed to every job defined in a downstream
pipeline. It is available as a variable when GitLab Runner picks a job.

In the following configuration, the `MY_VARIABLE` variable is passed to the downstream pipeline
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
upstream pipeline is passed to the `downstream-job` job, and is available
within the context of all downstream builds.

Upstream pipelines take precedence over downstream ones. If there are two
variables with the same name defined in both upstream and downstream projects,
the ones defined in the upstream project take precedence.

#### With variable inheritance

You can pass variables to a downstream pipeline with [`dotenv` variable inheritance](variables/README.md#pass-an-environment-variable-to-another-job) and [cross project artifact downloads](yaml/README.md#cross-project-artifact-downloads-with-needs).

In the upstream pipeline:

1. Save the variables in a `.env` file.
1. Save the `.env` file as a `dotenv` report.
1. Trigger the downstream pipeline.

```yaml
build_vars:
  stage: build
  script:
    - echo "BUILD_VERSION=hello" >> build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  stage: deploy
  trigger: my/downstream_project
```

Set the `test` job in the downstream pipeline to inherit the variables from the `build_vars`
job in the upstream project with `needs:`. The `test` job inherits the variables in the
`dotenv` report and it can access `BUILD_VERSION` in the script:

```yaml
test:
  stage: test
  script:
    - echo $BUILD_VERSION
  needs:
    - project: my/upstream_project
      job: build_vars
      ref: master
      artifacts: true
```

### Mirroring status from triggered pipeline

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11238) in GitLab Premium 12.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Free in 12.8.

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

Bridge jobs are a little different from regular jobs. It is not
possible to use exactly the same configuration syntax as when defining regular jobs
that are picked by a runner.

Some features are not implemented yet. For example, support for environments.

[Configuration keywords](yaml/README.md) available for bridge jobs are:

- `trigger` (to define a downstream pipeline trigger)
- `stage`
- `allow_failure`
- [`rules`](yaml/README.md#rules)
- `only` and `except`
- `when` (only with `on_success`, `on_failure`, and `always` values)
- `extends`
- `needs`

## Trigger a pipeline when an upstream project is rebuilt **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9045) in GitLab Premium 12.8.

You can trigger a pipeline in your project whenever a pipeline finishes for a new
tag in a different project:

1. Go to the project's **Settings > CI/CD** page, and expand the **Pipeline subscriptions** section.
1. Enter the project you want to subscribe to, in the format `<namespace>/<project>`.
   For example, if the project is `https://gitlab.com/gitlab-org/gitlab`, use `gitlab-org/gitlab`.
1. Click subscribe.

Any pipelines that complete successfully for new tags in the subscribed project
now trigger a pipeline on the current project's default branch. The maximum
number of upstream pipeline subscriptions is 2 by default, for both the upstream and
downstream projects. This [application limit](../administration/instance_limits.md#number-of-cicd-subscriptions-to-a-project) can be changed on self-managed instances by a GitLab administrator.

The upstream project needs to be [public](../public_access/public_access.md)
and the user must have [developer permissions](../user/permissions.md#project-members-permissions)
for the upstream project.

## Downstream private projects confidentiality concern

If you trigger a pipeline in a downstream private project, the name of the project
and the status of the pipeline is visible in the upstream project's pipelines page.

If you have a public project that can trigger downstream pipelines in a private
project, make sure to check that there are no confidentiality problems.
