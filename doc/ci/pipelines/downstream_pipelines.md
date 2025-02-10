---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Downstream pipelines
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

A downstream pipeline is any GitLab CI/CD pipeline triggered by another pipeline.
Downstream pipelines run independently and concurrently to the upstream pipeline
that triggered them.

- A [parent-child pipeline](downstream_pipelines.md#parent-child-pipelines) is a downstream pipeline
  triggered in the *same* project as the first pipeline.
- A [multi-project pipeline](#multi-project-pipelines) is a downstream pipeline triggered
  in a *different* project than the first pipeline.

You can sometimes use parent-child pipelines and multi-project pipelines for similar purposes,
but there are [key differences](pipeline_architectures.md).

## Parent-child pipelines

A parent pipeline is a pipeline that triggers a downstream pipeline in the same project.
The downstream pipeline is called a child pipeline.

Child pipelines:

- Run under the same project, ref, and commit SHA as the parent pipeline.
- Do not directly affect the overall status of the ref the pipeline runs against. For example,
  if a pipeline fails for the main branch, it's common to say that "main is broken".
  The status of child pipelines only affects the status of the ref if the child
  pipeline is triggered with [`strategy:depend`](../yaml/_index.md#triggerstrategy).
- Are automatically canceled if the pipeline is configured with [`interruptible`](../yaml/_index.md#interruptible)
  when a new pipeline is created for the same ref.
- Are not displayed in the project's pipeline list. You can only view child pipelines on
  their parent pipeline's details page.

### Nested child pipelines

Parent and child pipelines have a maximum depth of two levels of child pipelines.

A parent pipeline can trigger many child pipelines, and these child pipelines can trigger
their own child pipelines. You cannot trigger another level of child pipelines.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Nested Dynamic Pipelines](https://youtu.be/C5j3ju9je2M).

## Multi-project pipelines

A pipeline in one project can trigger downstream pipelines in another project,
called multi-project pipelines. The user triggering the upstream pipeline must be able to
start pipelines in the downstream project, otherwise [the downstream pipeline fails to start](downstream_pipelines_troubleshooting.md#trigger-job-fails-and-does-not-create-multi-project-pipeline).

Multi-project pipelines:

- Are triggered from another project's pipeline, but the upstream (triggering) pipeline does
  not have much control over the downstream (triggered) pipeline. However, it can
  choose the ref of the downstream pipeline, and pass CI/CD variables to it.
- Affect the overall status of the ref of the project it runs in, but does not
  affect the status of the triggering pipeline's ref, unless it was triggered with
  [`strategy:depend`](../yaml/_index.md#triggerstrategy).
- Are not automatically canceled in the downstream project when using [`interruptible`](../yaml/_index.md#interruptible)
  if a new pipeline runs for the same ref in the upstream pipeline. They can be
  automatically canceled if a new pipeline is triggered for the same ref on the downstream project.
- Are visible in the downstream project's pipeline list.
- Are independent, so there are no nesting limits.

If you use a public project to trigger downstream pipelines in a private project,
make sure there are no confidentiality problems. The upstream project's pipelines page
always displays:

- The name of the downstream project.
- The status of the pipeline.

## Trigger a downstream pipeline from a job in the `.gitlab-ci.yml` file

Use the [`trigger`](../yaml/_index.md#trigger) keyword in your `.gitlab-ci.yml` file
to create a job that triggers a downstream pipeline. This job is called a trigger job.

For example:

::Tabs

:::TabTitle Parent-child pipeline

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

:::TabTitle Multi-project pipeline

```yaml
trigger_job:
  trigger:
    project: project-group/my-downstream-project
```

::EndTabs

After the trigger job starts, the initial status of the job is `pending` while GitLab
attempts to create the downstream pipeline. The trigger job shows `passed` if the
downstream pipeline is created successfully, otherwise it shows `failed`. Alternatively,
you can [set the trigger job to show the downstream pipeline's status](#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job)
instead.

### Use `rules` to control downstream pipeline jobs

Use CI/CD variables or the [`rules`](../yaml/_index.md#rulesif) keyword to
[control job behavior](../jobs/job_control.md) in downstream pipelines.

When you trigger a downstream pipeline with the [`trigger`](../yaml/_index.md#trigger) keyword,
the value of the [`$CI_PIPELINE_SOURCE` predefined variable](../variables/predefined_variables.md)
for all jobs is:

- `pipeline` for multi-project pipelines.
- `parent_pipeline` for parent-child pipelines.

For example, to control jobs in multi-project pipelines in a project that also runs
merge request pipelines:

```yaml
job1:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
  script: echo "This job runs in multi-project pipelines only"

job2:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in merge request pipelines only"

job3:
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline"
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script: echo "This job runs in both multi-project and merge request pipelines"
```

### Use a child pipeline configuration file in a different project

You can use [`include:project`](../yaml/_index.md#includeproject) in a trigger job
to trigger child pipelines with a configuration file in a different project:

```yaml
microservice_a:
  trigger:
    include:
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### Combine multiple child pipeline configuration files

You can include up to three configuration files when defining a child pipeline. The child pipeline's
configuration is composed of all configuration files merged together:

```yaml
microservice_a:
  trigger:
    include:
      - local: path/to/microservice_a.yml
      - template: Jobs/SAST.gitlab-ci.yml
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### Dynamic child pipelines

You can trigger a child pipeline from a YAML file generated in a job, instead of a
static file saved in your project. This technique can be very powerful for generating pipelines
targeting content that changed or to build a matrix of targets and architectures.

The artifact containing the generated YAML file must not be [larger than 5 MB](https://gitlab.com/gitlab-org/gitlab/-/issues/249140).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Create child pipelines using dynamically generated configurations](https://youtu.be/nMdfus2JWHM).

For an example project that generates a dynamic child pipeline, see
[Dynamic Child Pipelines with Jsonnet](https://gitlab.com/gitlab-org/project-templates/jsonnet).
This project shows how to use a data templating language to generate your `.gitlab-ci.yml` at runtime.
You can use a similar process for other templating languages like
[Dhall](https://dhall-lang.org/) or [ytt](https://get-ytt.io/).

#### Trigger a dynamic child pipeline

To trigger a child pipeline from a dynamically generated configuration file:

1. Generate the configuration file in a job and save it as an [artifact](../yaml/_index.md#artifactspaths):

   ```yaml
   generate-config:
     stage: build
     script: generate-ci-config > generated-config.yml
     artifacts:
       paths:
         - generated-config.yml
   ```

1. Configure the trigger job to run after the job that generated the configuration file.
   Set `include: artifact` to the generated artifact, and set `include: job` to
   the job that created the artifact:

   ```yaml
   child-pipeline:
     stage: test
     trigger:
       include:
         - artifact: generated-config.yml
           job: generate-config
   ```

In this example, GitLab retrieves `generated-config.yml` and triggers a child pipeline
with the CI/CD configuration in that file.

The artifact path is parsed by GitLab, not the runner, so the path must match the
syntax for the OS running GitLab. If GitLab is running on Linux but using a Windows
runner for testing, the path separator for the trigger job is `/`. Other CI/CD
configuration for jobs that use the Windows runner, like scripts, use <code>&#92;</code>.

You cannot use CI/CD variables in an `include` section in a dynamic child pipeline's configuration.
[Issue 378717](https://gitlab.com/gitlab-org/gitlab/-/issues/378717) proposes fixing
this issue.

### Run child pipelines with merge request pipelines

Pipelines, including child pipelines, run as branch pipelines by default when not using
[`rules`](../yaml/_index.md#rules) or [`workflow:rules`](../yaml/_index.md#workflowrules).
To configure child pipelines to run when triggered from a [merge request (parent) pipeline](merge_request_pipelines.md), use `rules` or `workflow:rules`.
For example, using `rules`:

1. Set the parent pipeline's trigger job to run on merge requests:

   ```yaml
   trigger-child-pipeline-job:
     trigger:
       include: path/to/child-pipeline-configuration.yml
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
   ```

1. Use `rules` to configure the child pipeline jobs to run when triggered by the parent pipeline:

   ```yaml
   job1:
     script: echo "This child pipeline job runs any time the parent pipeline triggers it."
     rules:
       - if: $CI_PIPELINE_SOURCE == "parent_pipeline"

   job2:
     script: echo "This child pipeline job runs only when the parent pipeline is a merge request pipeline"
     rules:
       - if: $CI_MERGE_REQUEST_ID
   ```

In child pipelines, `$CI_PIPELINE_SOURCE` always has a value of `parent_pipeline`, so:

- You can use `if: $CI_PIPELINE_SOURCE == "parent_pipeline"` to ensure child pipeline jobs always run.
- You _can't_ use `if: $CI_PIPELINE_SOURCE == "merge_request_event"` to configure child pipeline
  jobs to run for merge request pipelines. Instead, use `if: $CI_MERGE_REQUEST_ID`
  to set child pipeline jobs to run only when the parent pipeline is a merge request pipeline. The parent pipeline's
  [`CI_MERGE_REQUEST_*` predefined variables](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)
  are passed to the child pipeline jobs.

### Specify a branch for multi-project pipelines

You can specify the branch to use when triggering a multi-project pipeline. GitLab uses
the commit on the head of the branch to create the downstream pipeline. For example:

```yaml
staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable-11-2
```

Use:

- The `project` keyword to specify the full path to the downstream project.
  In [GitLab 15.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/367660),
  you can use [variable expansion](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- The `branch` keyword to specify the name of a branch or [tag](../../user/project/repository/tags/_index.md)
  in the project specified by `project`. You can use variable expansion.

## Trigger a multi-project pipeline by using the API

You can use the [CI/CD job token (`CI_JOB_TOKEN`)](../jobs/ci_job_token.md) with the
[pipeline trigger API endpoint](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)
to trigger multi-project pipelines from inside a CI/CD job. GitLab sets pipelines triggered
with a job token as downstream pipelines of the pipeline that contains the job that
made the API call.

For example:

```yaml
trigger_pipeline:
  stage: deploy
  script:
    - curl --request POST --form "token=$CI_JOB_TOKEN" --form ref=main "https://gitlab.example.com/api/v4/projects/9/trigger/pipeline"
  rules:
    - if: $CI_COMMIT_TAG
  environment: production
```

## View a downstream pipeline

In the [pipeline details page](_index.md#pipeline-details), downstream pipelines display
as a list of cards on the right of the graph. From this view, you can:

- Select a trigger job to see the triggered downstream pipeline's jobs.
- Select **Expand jobs** **{chevron-lg-right}** on a pipeline card to expand the view
  with the downstream pipeline's jobs. You can view one downstream pipeline at a time.
- Hover over a pipeline card to have the job that triggered the downstream pipeline highlighted.

### Retry failed and canceled jobs in a downstream pipeline

> - Retry from graph view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354974) in GitLab 15.0 [with a flag](../../administration/feature_flags.md) named `downstream_retry_action`. Disabled by default.
> - Retry from graph view [generally available and feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/357406) in GitLab 15.1.

To retry failed and canceled jobs, select **Retry** (**{retry}**):

- From the downstream pipeline's details page.
- On the pipeline's card in the pipeline graph view.

### Recreate a downstream pipeline

> - Retry trigger job from graph view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367547) in GitLab 15.10 [with a flag](../../administration/feature_flags.md) named `ci_recreate_downstream_pipeline`. Disabled by default.
> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/6947) in GitLab 15.11. Feature flag `ci_recreate_downstream_pipeline` removed.

You can recreate a downstream pipeline by retrying its corresponding trigger job. The newly created downstream pipeline replaces the current downstream pipeline in the pipeline graph.

To recreate a downstream pipeline:

- Select **Run again** (**{retry}**) on the trigger job's card in the pipeline graph view.

### Cancel a downstream pipeline

> - Retry from graph view [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354974) in GitLab 15.0 [with a flag](../../administration/feature_flags.md) named `downstream_retry_action`. Disabled by default.
> - Retry from graph view [generally available and feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/357406) in GitLab 15.1.

To cancel a downstream pipeline that is still running, select **Cancel** (**{cancel}**):

- From the downstream pipeline's details page.
- On the pipeline's card in the pipeline graph view.

### Auto-cancel the parent pipeline from a downstream pipeline

You can configure a child pipeline to [auto-cancel](../yaml/_index.md#workflowauto_cancelon_job_failure)
as soon as one of its jobs fail.

The parent pipeline only auto-cancels when a job in the child pipeline fails if:

- The parent pipeline is also set up to auto-cancel on job failure.
- The trigger job is configured with [`strategy: depend`](../yaml/_index.md#triggerstrategy).

For example:

- Content of `.gitlab-ci.yml`:

  ```yaml
  workflow:
    auto_cancel:
      on_job_failure: all

  trigger_job:
    trigger:
      include: child-pipeline.yml
      strategy: depend

  job3:
    script:
      - sleep 120
  ```

- Content of `child-pipeline.yml`

  ```yaml
  # Contents of child-pipeline.yml
  workflow:
    auto_cancel:
      on_job_failure: all

  job1:
    script: sleep 60

  job2:
    script:
      - sleep 30
      - exit 1
  ```

In this example:

1. The parent pipeline triggers the child pipeline and `job3` at the same time
1. `job2` from the child pipeline fails and the child pipeline is canceled, stopping `job1` as well
1. The child pipeline has been canceled so the parent pipeline is auto-canceled

### Mirror the status of a downstream pipeline in the trigger job

You can mirror the status of the downstream pipeline in the trigger job
by using [`strategy: depend`](../yaml/_index.md#triggerstrategy):

::Tabs

:::TabTitle Parent-child pipeline

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
    strategy: depend
```

:::TabTitle Multi-project pipeline

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: depend
```

::EndTabs

### View multi-project pipelines in pipeline graphs

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/422282) from GitLab Premium to GitLab Free in 16.8.

After you trigger a multi-project pipeline, the downstream pipeline displays
to the right of the [pipeline graph](_index.md#view-pipelines).

In [pipeline mini graphs](_index.md#pipeline-mini-graphs), the downstream pipeline
displays to the right of the mini graph.

## Fetch artifacts from an upstream pipeline

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

::Tabs

:::TabTitle Parent-child pipeline

Use [`needs:pipeline:job`](../yaml/_index.md#needspipelinejob) to fetch artifacts from an
upstream pipeline:

1. In the upstream pipeline, save the artifacts in a job with the [`artifacts`](../yaml/_index.md#artifacts)
   keyword, then trigger the downstream pipeline with a trigger job:

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger:
       include:
         - local: path/to/child-pipeline.yml
     variables:
       PARENT_PIPELINE_ID: $CI_PIPELINE_ID
   ```

1. Use `needs:pipeline:job` in a job in the downstream pipeline to fetch the artifacts.

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - pipeline: $PARENT_PIPELINE_ID
         job: build_artifacts
   ```

   Set `job` to the job in the upstream pipeline that created the artifacts.

:::TabTitle Multi-project pipeline

Use [`needs:project`](../yaml/_index.md#needsproject) to fetch artifacts from an
upstream pipeline:

1. In GitLab 15.9 and later, [add the downstream project to the job token scope allowlist](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) of the upstream project.
1. In the upstream pipeline, save the artifacts in a job with the [`artifacts`](../yaml/_index.md#artifacts)
   keyword, then trigger the downstream pipeline with a trigger job:

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   deploy:
     stage: deploy
     trigger: my/downstream_project   # Path to the project to trigger a pipeline in
   ```

1. Use `needs:project` in a job in the downstream pipeline to fetch the artifacts.

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: main
         artifacts: true
   ```

   Set:

   - `job` to the job in the upstream pipeline that created the artifacts.
   - `ref` to the branch.
   - `artifacts` to `true`.

::EndTabs

### Fetch artifacts from an upstream merge request pipeline

When you use `needs:project` to [pass artifacts to a downstream pipeline](#fetch-artifacts-from-an-upstream-pipeline),
the `ref` value is usually a branch name, like `main` or `development`.

For [merge request pipelines](merge_request_pipelines.md), the `ref` value is in the form of `refs/merge-requests/<id>/head`,
where `id` is the merge request ID. You can retrieve this ref with the [`CI_MERGE_REQUEST_REF_PATH`](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)
CI/CD variable. Do not use a branch name as the `ref` with merge request pipelines,
because the downstream pipeline attempts to fetch artifacts from the latest branch pipeline.

To fetch the artifacts from the upstream `merge request` pipeline instead of the `branch` pipeline,
pass `CI_MERGE_REQUEST_REF_PATH` to the downstream pipeline using [variable inheritance](#pass-yaml-defined-cicd-variables):

1. In GitLab 15.9 and later, [add the downstream project to the job token scope allowlist](../jobs/ci_job_token.md#add-a-group-or-project-to-the-job-token-allowlist) of the upstream project.
1. In a job in the upstream pipeline, save the artifacts using the [`artifacts`](../yaml/_index.md#artifacts) keyword.
1. In the job that triggers the downstream pipeline, pass the `$CI_MERGE_REQUEST_REF_PATH` variable:

   ```yaml
   build_artifacts:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   upstream_job:
     rules:
       - if: $CI_PIPELINE_SOURCE == 'merge_request_event'
     variables:
       UPSTREAM_REF: $CI_MERGE_REQUEST_REF_PATH
     trigger:
       project: my/downstream_project
       branch: my-branch
   ```

1. In a job in the downstream pipeline, fetch the artifacts from the upstream pipeline
   by using `needs:project` and the passed variable as the `ref`:

   ```yaml
   test:
     stage: test
     script:
       - cat artifact.txt
     needs:
       - project: my/upstream_project
         job: build_artifacts
         ref: $UPSTREAM_REF
         artifacts: true
   ```

You can use this method to fetch artifacts from upstream merge request pipelines,
but not from [merged results pipelines](merged_results_pipelines.md).

## Pass CI/CD variables to a downstream pipeline

You can pass [CI/CD variables](../variables/_index.md) to a downstream pipeline with
a few different methods, based on where the variable is created or defined.

### Pass YAML-defined CI/CD variables

You can use the `variables` keyword to pass CI/CD variables to a downstream pipeline.
These variables are "trigger variables" for [variable precedence](../variables/_index.md#cicd-variable-precedence).

For example:

::Tabs

:::TabTitle Parent-child pipeline

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

:::TabTitle Multi-project pipeline

```yaml
variables:
  VERSION: "1.0.0"

staging:
  variables:
    ENVIRONMENT: staging
  stage: deploy
  trigger: my-group/my-deployment-project
```

::EndTabs

The `ENVIRONMENT` variable is available in every job defined in the downstream pipeline.

The `VERSION` default variable is also available in the downstream pipeline, because
all jobs in a pipeline, including trigger jobs, inherit [default `variables`](../yaml/_index.md#default-variables).

#### Prevent default variables from being passed

You can stop default CI/CD variables from reaching the downstream pipeline with
[`inherit:variables:false`](../yaml/_index.md#inheritvariables).

For example:

::Tabs

:::TabTitle Parent-child pipeline

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

:::TabTitle Multi-project pipeline

```yaml
variables:
  DEFAULT_VAR: value

trigger-job:
  inherit:
    variables: false
  variables:
    JOB_VAR: value
  trigger: my-group/my-project
```

::EndTabs

The `DEFAULT_VAR` variable is not available in the triggered pipeline, but `JOB_VAR`
is available.

### Pass a predefined variable

To pass information about the upstream pipeline using [predefined CI/CD variables](../variables/predefined_variables.md)
use interpolation. Save the predefined variable as a new job variable in the trigger
job, which is passed to the downstream pipeline. For example:

::Tabs

:::TabTitle Parent-child pipeline

```yaml
trigger-job:
  variables:
    PARENT_BRANCH: $CI_COMMIT_REF_NAME
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

:::TabTitle Multi-project pipeline

```yaml
trigger-job:
  variables:
    UPSTREAM_BRANCH: $CI_COMMIT_REF_NAME
  trigger: my-group/my-project
```

::EndTabs

The `UPSTREAM_BRANCH` variable, which contains the value of the upstream pipeline's `$CI_COMMIT_REF_NAME`
predefined CI/CD variable, is available in the downstream pipeline.

Do not use this method to pass [masked variables](../variables/_index.md#mask-a-cicd-variable)
to a multi-project pipeline. The CI/CD masking configuration is not passed to the
downstream pipeline and the variable could be unmasked in job logs in the downstream project.

You cannot use this method to forward [job-only variables](../variables/predefined_variables.md#variable-availability)
to a downstream pipeline, as they are not available in trigger jobs.

Upstream pipelines take precedence over downstream ones. If there are two
variables with the same name defined in both upstream and downstream projects,
the ones defined in the upstream project take precedence.

### Pass dotenv variables created in a job

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

You can pass variables to a downstream pipeline with [`dotenv` variable inheritance](../variables/_index.md#pass-an-environment-variable-to-another-job).

For example, in a [multi-project pipeline](#multi-project-pipelines):

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

### Control what type of variables to forward to downstream pipelines

Use the [`trigger:forward` keyword](../yaml/_index.md#triggerforward) to specify
what type of variables to forward to the downstream pipeline. Forwarded variables
are considered trigger variables, which have the [highest precedence](../variables/_index.md#cicd-variable-precedence).

## Downstream pipelines for deployments

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/369061) in GitLab 16.4.

You can use the [`environment`](../yaml/_index.md#environment) keyword with [`trigger`](../yaml/_index.md#trigger).
You might want to use `environment` from a trigger job if your deployment and application projects are separately managed.

```yaml
deploy:
  trigger:
    project: project-group/my-downstream-project
  environment: production
```

A downstream pipeline can provision infrastructure, deploy to a designated environment, and return the deployment status
to the upstream project.

You can [view the environment and deployment](../environments/_index.md#view-environments-and-deployments)
from the upstream project.

### Advanced example

This example configuration has the following behaviors:

- The upstream project dynamically composes an environment name based on a branch name.
- The upstream project passes the context of the deployment to the downstream project with `UPSTREAM_*` variables.

The `.gitlab-ci.yml` in an upstream project:

```yaml
stages:
  - deploy
  - cleanup

.downstream-deployment-pipeline:
  variables:
    UPSTREAM_PROJECT_ID: $CI_PROJECT_ID
    UPSTREAM_ENVIRONMENT_NAME: $CI_ENVIRONMENT_NAME
    UPSTREAM_ENVIRONMENT_ACTION: $CI_ENVIRONMENT_ACTION
  trigger:
    project: project-group/deployment-project
    branch: main
    strategy: depend

deploy-review:
  stage: deploy
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    on_stop: stop-review

stop-review:
  stage: cleanup
  extends: .downstream-deployment-pipeline
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
  when: manual
```

The `.gitlab-ci.yml` in a downstream project:

```yaml
deploy:
  script: echo "Deploy to ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "start"

stop:
  script: echo "Stop ${UPSTREAM_ENVIRONMENT_NAME} for ${UPSTREAM_PROJECT_ID}"
  rules:
    - if: $CI_PIPELINE_SOURCE == "pipeline" && $UPSTREAM_ENVIRONMENT_ACTION == "stop"
```
