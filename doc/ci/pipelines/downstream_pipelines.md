---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Downstream pipelines **(FREE)**

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

A parent pipeline is one that triggers a downstream pipeline in the same project.
The downstream pipeline is called a child pipeline. Child pipelines:

- Run under the same project, ref, and commit SHA as the parent pipeline.
- Do not directly affect the overall status of the ref the pipeline runs against. For example,
  if a pipeline fails for the main branch, it's common to say that "main is broken".
  The status of child pipelines only affects the status of the ref if the child
  pipeline is triggered with [`strategy:depend`](../yaml/index.md#triggerstrategy).
- Are automatically canceled if the pipeline is configured with [`interruptible`](../yaml/index.md#interruptible)
  when a new pipeline is created for the same ref.
- Are not displayed in the pipeline index page. You can only view child pipelines on
  their parent pipeline's page.

### Nested child pipelines

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29651) in GitLab 13.4.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/243747) in GitLab 13.5.

Parent and child pipelines were introduced with a maximum depth of one level of child
pipelines, which was later increased to two. A parent pipeline can trigger many child
pipelines, and these child pipelines can trigger their own child pipelines. It's not
possible to trigger another level of child pipelines.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Nested Dynamic Pipelines](https://youtu.be/C5j3ju9je2M).

## Multi-project pipelines

A pipeline in one project can trigger downstream pipelines in another project,
called multi-project pipelines. The user triggering the upstream pipeline must be able to
start pipelines in the downstream project, otherwise [the downstream pipeline fails to start](#trigger-job-fails-and-does-not-create-multi-project-pipeline).

For example, you might deploy your web application from three different GitLab projects.
With multi-project pipelines you can trigger a pipeline in each project, where each
has its own build, test, and deploy process. You can visualize the connected pipelines
in one place, including all cross-project interdependencies.

Multi-project pipelines:

- Are triggered from another project's pipeline, but the upstream (triggering) pipeline does
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

Learn more in the "Cross-project Pipeline Triggering and Visualization" demo at
[GitLab@learn](https://about.gitlab.com/learn/), in the Continuous Integration section.

If you use a public project to trigger downstream pipelines in a private project,
make sure there are no confidentiality problems. The upstream project's pipelines page
always displays:

- The name of the downstream project.
- The status of the pipeline.

## Trigger a downstream pipeline from a job in the `.gitlab-ci.yml` file

Use the [`trigger`](../yaml/index.md#trigger) keyword in your `.gitlab-ci.yml` file
to create a job that triggers a downstream pipeline. This job is called a trigger job.

After the trigger job starts, the initial status of the job is `pending` while GitLab
attempts to create the downstream pipeline. If the downstream pipeline is created,
GitLab marks the job as passed, otherwise the job failed. Alternatively,
you can [set the trigger job to show the downstream pipeline's status](#mirror-the-status-of-a-downstream-pipeline-in-the-trigger-job)
instead.

For example:

::Tabs

:::TabTitle Multi-project pipeline

```yaml
trigger_job:
  trigger:
    project: project-group/my-downstream-project
```

:::TabTitle Parent-child pipeline

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
```

::EndTabs

### Use `rules` to control downstream pipeline jobs

You can use CI/CD variables or the [`rules`](../yaml/index.md#rulesif) keyword to
[control job behavior](../jobs/job_control.md) for downstream pipelines.

When a downstream pipeline is triggered with the [`trigger`](../yaml/index.md#trigger) keyword,
the value of the [`$CI_PIPELINE_SOURCE` predefined variable](../variables/predefined_variables.md)
for all jobs is:

- `pipeline` for multi-project pipelines.
- `parent` for parent-child pipelines.

For example, with a multi-project pipeline:

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

### Specify a branch for multi-project pipelines

You can specify a branch name for a multi-project pipeline to use. GitLab uses
the commit on the head of the branch to create the downstream pipeline:

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
  In [GitLab 15.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/367660), variable expansion is
  supported.
- The `branch` keyword to specify the name of a branch or [tag](../../topics/git/tags.md)
  in the project specified by `project`. If you use a tag when a branch exists with the same
  name, the downstream pipeline fails to create with the error: `downstream pipeline can not be created, Ref is ambiguous`.

  In [GitLab 12.4 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/10126), variable expansion is
  supported.

### Use a child pipeline configuration file in a different project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/205157) in GitLab 13.5.

You can use [`include:file`](../yaml/index.md#includefile) to trigger child pipelines
with a configuration file in a different project:

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
      - template: Security/SAST.gitlab-ci.yml
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

### Dynamic child pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35632) in GitLab 12.9.

You can trigger a child pipeline from a YAML file generated in a job, instead of a
static file saved in your project. This technique can be very powerful for generating pipelines
targeting content that changed or to build a matrix of targets and architectures.

The artifact containing the generated YAML file must not be [larger than 5MB](https://gitlab.com/gitlab-org/gitlab/-/issues/249140).

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Create child pipelines using dynamically generated configurations](https://youtu.be/nMdfus2JWHM).

For an example project that generates a dynamic child pipeline, see
[Dynamic Child Pipelines with Jsonnet](https://gitlab.com/gitlab-org/project-templates/jsonnet).
This project shows how to use a data templating language to generate your `.gitlab-ci.yml` at runtime.
You can use a similar process for other templating languages like
[Dhall](https://dhall-lang.org/) or [ytt](https://get-ytt.io/).

#### Trigger a dynamic child pipeline

To trigger a child pipeline from a dynamically generated configuration file:

1. Generate the configuration file in a job and save it as an [artifact](../yaml/index.md#artifactspaths):

  ```yaml
  generate-config:
    stage: build
    script: generate-ci-config > generated-config.yml
    artifacts:
      paths:
        - generated-config.yml
  ```

1. Configure the trigger job to run after the job that generated the configuration file,
   and set `include: artifact` to the generated artifact:

  ```yaml
  child-pipeline:
    stage: test
    trigger:
      include:
        - artifact: generated-config.yml
          job: generate-config
  ```

In this example, `generated-config.yml` is extracted from the artifacts and used as the configuration
for triggering the child pipeline.

The artifact path is parsed by GitLab, not the runner, so the path must match the
syntax for the OS running GitLab. If GitLab is running on Linux but using a Windows
runner for testing, the path separator for the trigger job is `/`. Other CI/CD
configuration for jobs that use the Windows runner, like scripts, use `\`.

### Run child pipelines with merge request pipelines

To trigger a child pipeline as a [merge request pipeline](merge_request_pipelines.md):

1. Set the trigger job to run on merge requests:

   ```yaml
   # parent .gitlab-ci.yml
   microservice_a:
     trigger:
       include: path/to/microservice_a.yml
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
   ```

1. Configure the child pipeline jobs to run in merge request pipelines:

   - With [`workflow:rules`](../yaml/index.md#workflowrules):

     ```yaml
     # child path/to/microservice_a.yml
     workflow:
       rules:
         - if: $CI_PIPELINE_SOURCE == "merge_request_event"

     job1:
       script: ...

     job2:
       script: ...
     ```

   - By configuring [rules](../yaml/index.md#rules) for each job:

     ```yaml
     # child path/to/microservice_a.yml
     job1:
       script: ...
       rules:
         - if: $CI_PIPELINE_SOURCE == "merge_request_event"

     job2:
       script: ...
       rules:
         - if: $CI_PIPELINE_SOURCE == "merge_request_event"
     ```

## Trigger a multi-project pipeline by using the API

You can use the [CI/CD job token (`CI_JOB_TOKEN`)](../jobs/ci_job_token.md) with the
[pipeline trigger API endpoint](../../api/pipeline_triggers.md#trigger-a-pipeline-with-a-token)
to trigger multi-project pipelines from a CI/CD job. GitLab recognizes the source of the job token
and marks the pipelines as related. In the pipeline graph, the relationships are displayed
as inbound and outbound connections for upstream and downstream pipeline dependencies.

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

> Hover behavior for pipeline cards [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/197140/) in GitLab 13.2.

In the [pipeline graph view](index.md#view-full-pipeline-graph), downstream pipelines display
as a list of cards on the right of the graph. Hover over the pipeline's card to view
which job triggered the downstream pipeline.

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

You can mirror the pipeline status from the triggered pipeline to the source trigger job
by using [`strategy: depend`](../yaml/index.md#triggerstrategy):

::Tabs

:::TabTitle Multi-project pipeline

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: depend
```

:::TabTitle Parent-child pipeline

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
    strategy: depend
```

::EndTabs

### View multi-project pipelines in pipeline graphs **(PREMIUM)**

When you trigger a multi-project pipeline, the downstream pipeline displays
to the right of the [pipeline graph](index.md#visualize-pipelines).

![Multi-project pipeline graph](img/multi_project_pipeline_graph_v14_3.png)

In [pipeline mini graphs](index.md#pipeline-mini-graphs), the downstream pipeline
displays to the right of the mini graph.

![Multi-project pipeline mini graph](img/pipeline_mini_graph_v15_0.png)

## Pass artifacts to a downstream pipeline

You can pass artifacts to a downstream pipeline by using [`needs:project`](../yaml/index.md#needsproject).

1. In a job in the upstream pipeline, save the artifacts using the [`artifacts`](../yaml/index.md#artifacts) keyword.
1. Trigger the downstream pipeline with a trigger job:

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
     trigger: my/downstream_project
   ```

1. In a job in the downstream pipeline, fetch the artifacts from the upstream pipeline
   by using `needs:project`. Set `job` to the job in the upstream pipeline to fetch artifacts from,
   `ref` to the branch, and `artifacts: true`.

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

### Pass artifacts from a Merge Request pipeline

When you use `needs:project` to [pass artifacts to a downstream pipeline](#pass-artifacts-to-a-downstream-pipeline),
the `ref` value is usually a branch name, like `main` or `development`.

For merge request pipelines, the `ref` value is in the form of `refs/merge-requests/<id>/head`,
where `id` is the merge request ID. You can retrieve this ref with the [`CI_MERGE_REQUEST_REF_PATH`](../variables/predefined_variables.md#predefined-variables-for-merge-request-pipelines)
CI/CD variable. Do not use a branch name as the `ref` with merge request pipelines,
because the downstream pipeline attempts to fetch artifacts from the latest branch pipeline.

To fetch the artifacts from the upstream `merge request` pipeline instead of the `branch` pipeline,
pass this variable to the downstream pipeline using variable inheritance:

1. In a job in the upstream pipeline, save the artifacts using the [`artifacts`](../yaml/index.md#artifacts) keyword.
1. In the job that triggers the downstream pipeline, pass the `$CI_MERGE_REQUEST_REF_PATH` variable by using
   [variable inheritance](#pass-yaml-defined-cicd-variables):

   ```yaml
   build_artifacts:
     stage: build
     script:
       - echo "This is a test artifact!" >> artifact.txt
     artifacts:
       paths:
         - artifact.txt

   upstream_job:
     variables:
       UPSTREAM_REF: $CI_MERGE_REQUEST_REF_PATH
     trigger:
       project: my/downstream_project
       branch: my-branch
   ```

1. In a job in the downstream pipeline, fetch the artifacts from the upstream pipeline
   by using `needs:project`. Set the `ref` to the `UPSTREAM_REF` variable, and `job`
   to the job in the upstream pipeline to fetch artifacts from:

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

This method works for fetching artifacts from a regular merge request parent pipeline,
but fetching artifacts from [merge results](merged_results_pipelines.md) pipelines is not supported.

## Pass CI/CD variables to a downstream pipeline

You can pass CI/CD variables to a downstream pipeline with a few different methods,
based on where the variable is created or defined.

### Pass YAML-defined CI/CD variables

You can use the `variables` keyword to pass CI/CD variables to a downstream pipeline,
just like you would for any other job.

For example, in a [multi-project pipeline](#multi-project-pipelines):

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
that is created when the `trigger-downstream` job is queued. This behavior is because `trigger-downstream`
job inherits variables declared in [global `variables`](../yaml/index.md#variables) blocks,
and then GitLab passes these variables to the downstream pipeline.

```yaml
variables:
  MY_VARIABLE: my-value

trigger-downstream:
  variables:
    ENVIRONMENT: something
  trigger: my/project
```

#### Prevent global variables from being passed

You can stop global variables from reaching the downstream pipeline by using the [`inherit:variables` keyword](../yaml/index.md#inheritvariables).
For example, in a [multi-project pipeline](#multi-project-pipelines):

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
in a [multi-project pipeline](#multi-project-pipelines):

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

## Troubleshooting

### Trigger job fails and does not create multi-project pipeline

With multi-project pipelines, the trigger job fails and does not create the downstream pipeline if:

- The downstream project is not found.
- The user that creates the upstream pipeline does not have [permission](../../user/permissions.md)
  to create pipelines in the downstream project.
- The downstream pipeline targets a protected branch and the user does not have permission
  to run pipelines against the protected branch. See [pipeline security for protected branches](index.md#pipeline-security-on-protected-branches)
  for more information.
