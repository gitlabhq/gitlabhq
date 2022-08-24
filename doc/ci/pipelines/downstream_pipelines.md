---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Downstream pipelines **(FREE)**

A downstream pipeline is any GitLab CI/CD pipeline triggered by another pipeline.
A downstream pipeline can be either:

- A [parent-child pipeline](parent_child_pipelines.md), which is a downstream pipeline triggered
  in the same project as the first pipeline.
- A [multi-project pipeline](multi_project_pipelines.md), which is a downstream pipeline triggered
  in a different project than the first pipeline.

Parent-child pipelines and multi-project pipelines can sometimes be used for similar purposes,
but there are some key differences.

Parent-child pipelines:

- Run under the same project, ref, and commit SHA as the parent pipeline.
- Affect the overall status of the ref the pipeline runs against. For example,
  if a pipeline fails for the main branch, it's common to say that "main is broken".
  The status of child pipelines don't directly affect the status of the ref, unless the child
  pipeline is triggered with [`strategy:depend`](../yaml/index.md#triggerstrategy).
- Are automatically canceled if the pipeline is configured with [`interruptible`](../yaml/index.md#interruptible)
  when a new pipeline is created for the same ref.
- Display only the parent pipelines in the pipeline index page. Child pipelines are
  visible when visiting their parent pipeline's page.
- Are limited to 2 levels of nesting. A parent pipeline can trigger multiple child pipelines,
  and those child pipeline can trigger multiple child pipelines (`A -> B -> C`).

Multi-project pipelines:

- Are triggered from another pipeline, but the upstream (triggering) pipeline does
  not have much control over the downstream (triggered) pipeline. However, it can
  choose the ref of the downstream pipeline, and pass CI/CD variables to it.
- Affect the overall status of the ref of the project it runs in, but does not
  affect the status of the triggering pipeline's ref, unless it was triggered with
  [`strategy:depend`](../yaml/index.md#triggerstrategy).
- Are not automatically canceled in the downstream project when using [`interruptible`](../yaml/index.md#interruptible)
  if a new pipeline runs for the same ref in the upstream pipeline. They can be
  automatically canceled if a new pipeline is triggered for the same ref on the downstream project.
- Multi-project pipelines are standalone pipelines because they are normal pipelines
  that happened to be triggered by an external project. They are all visible on the pipeline index page.
- Are independent, so there are no nesting limits.

## View a downstream pipeline

In the [pipeline graph view](index.md#view-full-pipeline-graph), downstream pipelines display
as a list of cards on the right of the graph.

### Retry a downstream pipeline

> - Retry from graph view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354974) in GitLab 15.0 [with a flag](../../administration/feature_flags.md) named `downstream_retry_action`. Disabled by default.
> - Retry from graph view [generally available and feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/357406) in GitLab 15.1.

To retry a completed downstream pipeline, select **Retry** (**{retry}**):

- From the downstream pipeline's details page.
- On the pipeline's card in the [pipeline graph view](index.md#view-full-pipeline-graph).

### Cancel a downstream pipeline

> - Retry from graph view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354974) in GitLab 15.0 [with a flag](../../administration/feature_flags.md) named `downstream_retry_action`. Disabled by default.
> - Retry from graph view [generally available and feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/357406) in GitLab 15.1.

To cancel a downstream pipeline that is still running, select **Cancel** (**{cancel}**):

- From the downstream pipeline's details page.
- On the pipeline's card in the [pipeline graph view](index.md#view-full-pipeline-graph).

### Mirror the status of a downstream pipeline in the trigger job

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/11238) in GitLab Premium 12.3.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Free in 12.8.

You can mirror the pipeline status from the triggered pipeline to the source trigger job
by using [`strategy: depend`](../yaml/index.md#triggerstrategy). For example:

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: depend
```

## Pass CI/CD variables to a downstream pipeline

You can pass CI/CD variables to a downstream pipeline with a few different methods,
based on where the variable is created or defined.

### Pass YAML-defined CI/CD variables

You can use the `variables` keyword to pass CI/CD variables to a downstream pipeline,
just like you would for any other job.

For example, in a [multi-project pipeline](multi_project_pipelines.md):

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

### Prevent global variables from being passed

You can stop global variables from reaching the downstream pipeline by using the [`inherit:variables` keyword](../yaml/index.md#inheritvariables).
For example, in a [multi-project pipeline](multi_project_pipelines.md):

```yaml
variables:
  MY_GLOBAL_VAR: value

trigger-downstream:
  inherit:
    variables: false
  variables:
    MY_LOCAL_VAR: value
  trigger: my/project
```

In this example, the `MY_GLOBAL_VAR` variable is not available in the triggered pipeline.

### Pass a predefined variable

You might want to pass some information about the upstream pipeline using predefined variables.
To do that, you can use interpolation to pass any variable. For example,
in a [multi-project pipeline](multi_project_pipelines.md):

```yaml
downstream-job:
  variables:
    UPSTREAM_BRANCH: $CI_COMMIT_REF_NAME
  trigger: my/project
```

In this scenario, the `UPSTREAM_BRANCH` variable with the value of the upstream pipeline's
`$CI_COMMIT_REF_NAME` is passed to `downstream-job`. It is available in the
context of all downstream builds.

You cannot use this method to forward [job-level persisted variables](../variables/where_variables_can_be_used.md#persisted-variables)
to a downstream pipeline, as they are not available in trigger jobs.

Upstream pipelines take precedence over downstream ones. If there are two
variables with the same name defined in both upstream and downstream projects,
the ones defined in the upstream project take precedence.

### Pass dotenv variables created in a job **(PREMIUM)**

You can pass variables to a downstream pipeline with [`dotenv` variable inheritance](../variables/index.md#pass-an-environment-variable-to-another-job)
and [`needs:project`](../yaml/index.md#needsproject).

For example, in a [multi-project pipeline](multi_project_pipelines.md):

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

1. Set the `test` job in the downstream pipeline to inherit the variables from the `build_vars`
   job in the upstream project with `needs`. The `test` job inherits the variables in the
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
