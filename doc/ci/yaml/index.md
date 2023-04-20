---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
type: reference
---

# `.gitlab-ci.yml` keyword reference **(FREE)**

This document lists the configuration options for your GitLab `.gitlab-ci.yml` file.

- For a quick introduction to GitLab CI/CD, follow the [quick start guide](../quick_start/index.md).
- For a collection of examples, see [GitLab CI/CD Examples](../examples/index.md).
- To view a large `.gitlab-ci.yml` file used in an enterprise, see the [`.gitlab-ci.yml` file for `gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml).

When you are editing your `.gitlab-ci.yml` file, you can validate it with the
[CI Lint](../lint.md) tool.

If you are editing content on this page, follow the [instructions for documenting keywords](../../development/cicd/cicd_reference_documentation_guide.md).

## Keywords

A GitLab CI/CD pipeline configuration includes:

- [Global keywords](#global-keywords) that configure pipeline behavior:

  | Keyword                   | Description |
  |---------------------------|:------------|
  | [`default`](#default)     | Custom default values for job keywords. |
  | [`include`](#include)     | Import configuration from other YAML files. |
  | [`stages`](#stages)       | The names and order of the pipeline stages. |
  | [`variables`](#variables) | Define CI/CD variables for all job in the pipeline. |
  | [`workflow`](#workflow)   | Control what types of pipeline run. |

- [Jobs](../jobs/index.md) configured with [job keywords](#job-keywords):

  | Keyword                                     | Description |
  | :-------------------------------------------|:------------|
  | [`after_script`](#after_script)             | Override a set of commands that are executed after job. |
  | [`allow_failure`](#allow_failure)           | Allow job to fail. A failed job does not cause the pipeline to fail. |
  | [`artifacts`](#artifacts)                   | List of files and directories to attach to a job on success. |
  | [`before_script`](#before_script)           | Override a set of commands that are executed before job. |
  | [`cache`](#cache)                           | List of files that should be cached between subsequent runs. |
  | [`coverage`](#coverage)                     | Code coverage settings for a given job. |
  | [`dast_configuration`](#dast_configuration) | Use configuration from DAST profiles on a job level. |
  | [`dependencies`](#dependencies)             | Restrict which artifacts are passed to a specific job by providing a list of jobs to fetch artifacts from. |
  | [`environment`](#environment)               | Name of an environment to which the job deploys. |
  | [`except`](#only--except)                   | Control when jobs are not created. |
  | [`extends`](#extends)                       | Configuration entries that this job inherits from. |
  | [`image`](#image)                           | Use Docker images. |
  | [`inherit`](#inherit)                       | Select which global defaults all jobs inherit. |
  | [`interruptible`](#interruptible)           | Defines if a job can be canceled when made redundant by a newer run. |
  | [`needs`](#needs)                           | Execute jobs earlier than the stage ordering. |
  | [`only`](#only--except)                     | Control when jobs are created. |
  | [`pages`](#pages)                           | Upload the result of a job to use with GitLab Pages. |
  | [`parallel`](#parallel)                     | How many instances of a job should be run in parallel. |
  | [`release`](#release)                       | Instructs the runner to generate a [release](../../user/project/releases/index.md) object. |
  | [`resource_group`](#resource_group)         | Limit job concurrency. |
  | [`retry`](#retry)                           | When and how many times a job can be auto-retried in case of a failure. |
  | [`rules`](#rules)                           | List of conditions to evaluate and determine selected attributes of a job, and whether or not it's created. |
  | [`script`](#script)                         | Shell script that is executed by a runner. |
  | [`secrets`](#secrets)                       | The CI/CD secrets the job needs. |
  | [`services`](#services)                     | Use Docker services images. |
  | [`stage`](#stage)                           | Defines a job stage. |
  | [`tags`](#tags)                             | List of tags that are used to select a runner. |
  | [`timeout`](#timeout)                       | Define a custom job-level timeout that takes precedence over the project-wide setting. |
  | [`trigger`](#trigger)                       | Defines a downstream pipeline trigger. |
  | [`variables`](#variables)                   | Define job variables on a job level. |
  | [`when`](#when)                             | When to run job. |

## Global keywords

Some keywords are not defined in a job. These keywords control pipeline behavior
or import additional pipeline configuration.

### `default`

You can set global defaults for some keywords. Jobs that do not define one or more
of the listed keywords use the value defined in the `default` section.

**Keyword type**: Global keyword.

**Possible inputs**: These keywords can have custom defaults:

- [`after_script`](#after_script)
- [`artifacts`](#artifacts)
- [`before_script`](#before_script)
- [`cache`](#cache)
- [`hooks`](#hooks)
- [`image`](#image)
- [`interruptible`](#interruptible)
- [`retry`](#retry)
- [`services`](#services)
- [`tags`](#tags)
- [`timeout`](#timeout)

**Example of `default`**:

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: ruby:2.7
  script: bundle exec rspec
```

In this example, `ruby:3.0` is the default `image` value for all jobs in the pipeline.
The `rspec 2.7` job does not use the default, because it overrides the default with
a job-specific `image` section:

**Additional details**:

- When the pipeline is created, each default is copied to all jobs that don't have
  that keyword defined.
- If a job already has one of the keywords configured, the configuration in the job
  takes precedence and is not replaced by the default.
- Control inheritance of default keywords in jobs with [`inherit:default`](#inheritdefault).

### `include`

> [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/42861) to GitLab Free in 11.4.

Use `include` to include external YAML files in your CI/CD configuration.
You can split one long `.gitlab-ci.yml` file into multiple files to increase readability,
or reduce duplication of the same configuration in multiple places.

You can also store template files in a central repository and include them in projects.

The `include` files are:

- Merged with those in the `.gitlab-ci.yml` file.
- Always evaluated first and then merged with the content of the `.gitlab-ci.yml` file,
  regardless of the position of the `include` keyword.

You can have up to 150 includes per pipeline, including [nested](includes.md#use-nested-includes) includes:

- In [GitLab 15.10 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/367150) you can have up to 150 includes.
  In nested includes, the same file can be included multiple times, but duplicated includes
  count towards the limit.
- From [GitLab 14.9 to GitLab 15.9](https://gitlab.com/gitlab-org/gitlab/-/issues/28987), you can have up to 100 includes.
  The same file can be included multiple times in nested includes, but duplicates are ignored.
- In GitLab 14.9 and earlier you can have up to 100 includes, but the same file can not
  be included multiple times.

The time limit to resolve all files is 30 seconds.

**Keyword type**: Global keyword.

**Possible inputs**: The `include` subkeys:

- [`include:local`](#includelocal)
- [`include:project`](#includeproject)
- [`include:remote`](#includeremote)
- [`include:template`](#includetemplate)

**Additional details**:

- Only [certain CI/CD variables](includes.md#use-variables-with-include) can be used
  with `include` keywords.
- Use merging to customize and override included CI/CD configurations with local
- You can override included configuration by having the same job name or global keyword
  in the `.gitlab-ci.yml` file. The two configurations are merged together, and the
  configuration in the `.gitlab-ci.yml` file takes precedence over the included configuration.
- If you rerun a:
  - Job, the `include` files are not fetched again. All jobs in a pipeline use the configuration
    fetched when the pipeline was created. Any changes to the source `include` files
    do not affect job reruns.
  - Pipeline, the `include` files are fetched again. If they changed after the last
    pipeline run, the new pipeline uses the changed configuration.

**Related topics**:

- [Use variables with `include`](includes.md#use-variables-with-include).
- [Use `rules` with `include`](includes.md#use-rules-with-include).

#### `include:local`

Use `include:local` to include a file that is in the same repository as the configuration file containing the `include` keyword.
Use `include:local` instead of symbolic links.

**Keyword type**: Global keyword.

**Possible inputs**:

A full path relative to the root directory (`/`):

- The YAML file must have the extension `.yml` or `.yaml`.
- You can [use `*` and `**` wildcards in the file path](includes.md#use-includelocal-with-wildcard-file-paths).
- You can use [certain CI/CD variables](includes.md#use-variables-with-include).

**Example of `include:local`**:

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

You can also use shorter syntax to define the path:

```yaml
include: '.gitlab-ci-production.yml'
```

**Additional details**:

- The `.gitlab-ci.yml` file and the local file must be on the same branch.
- You can't include local files through Git submodules paths.
- All [nested includes](includes.md#use-nested-includes) are executed in the scope of the project containing the configuration file with the `include` keyword, not the project running the pipeline.
  You can use local, project, remote, or template includes.

#### `include:project`

> Including multiple files from the same project [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26793) in GitLab 13.6. [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/271560) in GitLab 13.8.

To include files from another private project on the same GitLab instance,
use `include:project` and `include:file`.

**Keyword type**: Global keyword.

**Possible inputs**:

- `include:project`: The full GitLab project path.
- `include:file` A full file path, or array of file paths, relative to the root directory (`/`).
  The YAML files must have the `.yml` or `.yaml` extension.
- `include:ref`: Optional. The ref to retrieve the file from. Defaults to the `HEAD` of the project
  when not specified.
- You can use [certain CI/CD variables](includes.md#use-variables-with-include).

**Example of `include:project`**:

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-subgroup/my-project-2'
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

You can also specify a `ref`:

```yaml
include:
  - project: 'my-group/my-project'
    ref: main                                      # Git branch
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: v1.0.0                                    # Git Tag
    file: '/templates/.gitlab-ci-template.yml'
  - project: 'my-group/my-project'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b  # Git SHA
    file: '/templates/.gitlab-ci-template.yml'
```

**Additional details**:

- All [nested includes](includes.md#use-nested-includes) are executed in the scope of the project containing the configuration file with the nested `include` keyword.
  You can use `local` (relative to the project containing the configuration file with the `include` keyword), `project`, `remote`, or `template` includes.
- When the pipeline starts, the `.gitlab-ci.yml` file configuration included by all methods is evaluated.
  The configuration is a snapshot in time and persists in the database. GitLab does not reflect any changes to
  the referenced `.gitlab-ci.yml` file configuration until the next pipeline starts.
- When you include a YAML file from another private project, the user running the pipeline
  must be a member of both projects and have the appropriate permissions to run pipelines.
  A `not found or access denied` error may be displayed if the user does not have access to any of the included files.

#### `include:remote`

Use `include:remote` with a full URL to include a file from a different location.

**Keyword type**: Global keyword.

**Possible inputs**:

A public URL accessible by an HTTP/HTTPS `GET` request:

- Authentication with the remote URL is not supported.
- The YAML file must have the extension `.yml` or `.yaml`.
- You can use [certain CI/CD variables](includes.md#use-variables-with-include).

**Example of `include:remote`**:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
```

**Additional details**:

- All [nested includes](includes.md#use-nested-includes) execute without context as a public user,
  so you can only include public projects or templates.
- Be careful when including a remote CI/CD configuration file. No pipelines or notifications
  trigger when external CI/CD configuration files change. From a security perspective,
  this is similar to pulling a third-party dependency.

#### `include:template`

Use `include:template` to include [`.gitlab-ci.yml` templates](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

**Keyword type**: Global keyword.

**Possible inputs**:

A [CI/CD template](../examples/index.md#cicd-templates):

- Templates are stored in [`lib/gitlab/ci/templates`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).
  Not all templates are designed to be used with `include:template`, so check template
  comments before using one.
- You can use [certain CI/CD variables](includes.md#use-variables-with-include).

**Example of `include:template`**:

```yaml
# File sourced from the GitLab template collection
include:
  - template: Auto-DevOps.gitlab-ci.yml
```

Multiple `include:template` files:

```yaml
include:
  - template: Android-Fastlane.gitlab-ci.yml
  - template: Auto-DevOps.gitlab-ci.yml
```

**Additional details**:

- All [nested includes](includes.md#use-nested-includes) are executed only with the permission of the user,
  so it's possible to use `project`, `remote`, or `template` includes.

### `stages`

Use `stages` to define stages that contain groups of jobs. Use [`stage`](#stage)
in a job to configure the job to run in a specific stage.

If `stages` is not defined in the `.gitlab-ci.yml` file, the default pipeline stages are:

- [`.pre`](#stage-pre)
- `build`
- `test`
- `deploy`
- [`.post`](#stage-post)

The order of the items in `stages` defines the execution order for jobs:

- Jobs in the same stage run in parallel.
- Jobs in the next stage run after the jobs from the previous stage complete successfully.

If a pipeline contains only jobs in the `.pre` or `.post` stages, it does not run.
There must be at least one other job in a different stage. `.pre` and `.post` stages
can be used in [required pipeline configuration](../../user/admin_area/settings/continuous_integration.md#required-pipeline-configuration)
to define compliance jobs that must run before or after project pipeline jobs.

**Keyword type**: Global keyword.

**Example of `stages`**:

```yaml
stages:
  - build
  - test
  - deploy
```

In this example:

1. All jobs in `build` execute in parallel.
1. If all jobs in `build` succeed, the `test` jobs execute in parallel.
1. If all jobs in `test` succeed, the `deploy` jobs execute in parallel.
1. If all jobs in `deploy` succeed, the pipeline is marked as `passed`.

If any job fails, the pipeline is marked as `failed` and jobs in later stages do not
start. Jobs in the current stage are not stopped and continue to run.

**Additional details**:

- If a job does not specify a [`stage`](#stage), the job is assigned the `test` stage.
- If a stage is defined but no jobs use it, the stage is not visible in the pipeline,
  which can help [compliance pipeline configurations](../../user/group/compliance_frameworks.md#compliance-pipelines):
  - Stages can be defined in the compliance configuration but remain hidden if not used.
  - The defined stages become visible when developers use them in job definitions.

**Related topics**:

- To make a job start earlier and ignore the stage order, use the [`needs`](#needs) keyword.

### `workflow`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29654) in GitLab 12.5

Use [`workflow`](workflow.md) to control pipeline behavior.

**Related topics**:

- [`workflow: rules` examples](workflow.md#workflow-rules-examples)
- [Switch between branch pipelines and merge request pipelines](workflow.md#switch-between-branch-pipelines-and-merge-request-pipelines)

#### `workflow:name`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/372538) in GitLab 15.5 [with a flag](../../administration/feature_flags.md) named `pipeline_name`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/376095) in GitLab 15.7.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/376095) in GitLab 15.8. Feature flag `pipeline_name` removed.

You can use `name` in `workflow:` to define a name for pipelines.

All pipelines are assigned the defined name. Any leading or trailing spaces in the name are removed.

**Possible inputs**:

- A string.
- [CI/CD variables](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- A combination of both.

**Examples of `workflow:name`**:

A simple pipeline name with a predefined variable:

```yaml
workflow:
  name: 'Pipeline for branch: $CI_COMMIT_BRANCH'
```

A configuration with different pipeline names depending on the pipeline conditions:

```yaml
variables:
  PROJECT1_PIPELINE_NAME: 'Default pipeline name'  # A default is not required.

workflow:
  name: '$PROJECT1_PIPELINE_NAME'
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      variables:
        PROJECT1_PIPELINE_NAME: 'MR pipeline: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME'
    - if: '$CI_MERGE_REQUEST_LABELS =~ /pipeline:run-in-ruby3/'
      variables:
        PROJECT1_PIPELINE_NAME: 'Ruby 3 pipeline'
```

**Additional details**:

- If the name is an empty string, the pipeline is not assigned a name. A name consisting
  of only CI/CD variables could evaluate to an empty string if all the variables are also empty.
- `workflow:rules:variables` become [global variables](#variables) available in all jobs,
  including [`trigger`](#trigger) jobs which forward variables to downstream pipelines by default.
  If the downstream pipeline uses the same variable, the [variable is overwritten](../variables/index.md#cicd-variable-precedence)
  by the upstream variable value. Be sure to either:
  - Use a unique variable name in every project's pipeline configuration, like `PROJECT1_PIPELINE_NAME`.
  - Use [`inherit:variables`](#inheritvariables) in the trigger job and list the
    exact variables you want to forward to the downstream pipeline.

#### `workflow:rules`

The `rules` keyword in `workflow` is similar to [`rules` defined in jobs](#rules),
but controls whether or not a whole pipeline is created.

When no rules evaluate to true, the pipeline does not run.

**Possible inputs**: You can use some of the same keywords as job-level [`rules`](#rules):

- [`rules: if`](#rulesif).
- [`rules: changes`](#ruleschanges).
- [`rules: exists`](#rulesexists).
- [`when`](#when), can only be `always` or `never` when used with `workflow`.
- [`variables`](#workflowrulesvariables).

**Example of `workflow:rules`**:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_TITLE =~ /-draft$/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

In this example, pipelines run if the commit title (first line of the commit message) does not end with `-draft`
and the pipeline is for either:

- A merge request
- The default branch.

**Additional details**:

- If your rules match both branch pipelines (other than the default branch) and merge request pipelines,
  [duplicate pipelines](../jobs/job_control.md#avoid-duplicate-pipelines) can occur.

**Related topics**:

- You can use the [`workflow:rules` templates](workflow.md#workflowrules-templates) to import
  a preconfigured `workflow: rules` entry.
- [Common `if` clauses for `workflow:rules`](workflow.md#common-if-clauses-for-workflowrules).
- [Use `rules` to run merge request pipelines](../pipelines/merge_request_pipelines.md#use-rules-to-add-jobs).

#### `workflow:rules:variables`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294232) in GitLab 13.11.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/300997) in GitLab 14.1.

You can use [`variables`](#variables) in `workflow:rules` to define variables for
specific pipeline conditions.

When the condition matches, the variable is created and can be used by all jobs
in the pipeline. If the variable is already defined at the global level, the `workflow`
variable takes precedence and overrides the global variable.

**Keyword type**: Global keyword.

**Possible inputs**: Variable name and value pairs:

- The name can use only numbers, letters, and underscores (`_`).
- The value must be a string.

**Example of `workflow:rules:variables`**:

```yaml
variables:
  DEPLOY_VARIABLE: "default-deploy"

workflow:
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      variables:
        DEPLOY_VARIABLE: "deploy-production"  # Override globally-defined DEPLOY_VARIABLE
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
    - when: always                            # Run the pipeline in other cases

job1:
  variables:
    DEPLOY_VARIABLE: "job1-default-deploy"
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      variables:                                   # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "job1-deploy-production"  # at the job level.
    - when: on_success                             # Run the job in other cases
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"

job2:
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

When the branch is the default branch:

- job1's `DEPLOY_VARIABLE` is `job1-deploy-production`.
- job2's `DEPLOY_VARIABLE` is `deploy-production`.

When the branch is `feature`:

- job1's `DEPLOY_VARIABLE` is `job1-default-deploy`, and `IS_A_FEATURE` is `true`.
- job2's `DEPLOY_VARIABLE` is `default-deploy`, and `IS_A_FEATURE` is `true`.

When the branch is something else:

- job1's `DEPLOY_VARIABLE` is `job1-default-deploy`.
- job2's `DEPLOY_VARIABLE` is `default-deploy`.

**Additional details**:

- `workflow:rules:variables` become [global variables](#variables) available in all jobs,
  including [`trigger`](#trigger) jobs which forward variables to downstream pipelines by default.
  If the downstream pipeline uses the same variable, the [variable is overwritten](../variables/index.md#cicd-variable-precedence)
  by the upstream variable value. Be sure to either:
  - Use unique variable names in every project's pipeline configuration, like `PROJECT1_VARIABLE_NAME`.
  - Use [`inherit:variables`](#inheritvariables) in the trigger job and list the
    exact variables you want to forward to the downstream pipeline.

## Job keywords

The following topics explain how to use keywords to configure CI/CD pipelines.

### `after_script`

Use `after_script` to define an array of commands that run after each job, including failed jobs.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**: An array including:

- Single line commands.
- Long commands [split over multiple lines](script.md#split-long-commands).
- [YAML anchors](yaml_optimization.md#yaml-anchors-for-scripts).

CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Example of `after_script`**:

```yaml
job:
  script:
    - echo "An example script section."
  after_script:
    - echo "Execute this command after the `script` section completes."
```

**Additional details**:

Scripts you specify in `after_script` execute in a new shell, separate from any
`before_script` or `script` commands. As a result, they:

- Have the current working directory set back to the default (according to the [variables which define how the runner processes Git requests](../runners/configure_runners.md#configure-runner-behavior-with-variables)).
- Don't have access to changes done by commands defined in the `before_script` or `script`,
  including:
  - Command aliases and variables exported in `script` scripts.
  - Changes outside of the working tree (depending on the runner executor), like
    software installed by a `before_script` or `script` script.
- Have a separate timeout, which is [hard-coded to 5 minutes](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2716).
- Don't affect the job's exit code. If the `script` section succeeds and the
  `after_script` times out or fails, the job exits with code `0` (`Job Succeeded`).

If a job times out or is cancelled, the `after_script` commands do not execute.
[An issue exists](https://gitlab.com/gitlab-org/gitlab/-/issues/15603) to add support for executing `after_script` commands for timed-out or cancelled jobs.

**Related topics**:

- [Use `after_script` with `default`](script.md#set-a-default-before_script-or-after_script-for-all-jobs)
  to define a default array of commands that should run after all jobs.
- You can [ignore non-zero exit codes](script.md#ignore-non-zero-exit-codes).
- [Use color codes with `after_script`](script.md#add-color-codes-to-script-output)
  to make job logs easier to review.
- [Create custom collapsible sections](../jobs/index.md#custom-collapsible-sections)
  to simplify job log output.

### `allow_failure`

Use `allow_failure` to determine whether a pipeline should continue running when a job fails.

- To let the pipeline continue running subsequent jobs, use `allow_failure: true`.
- To stop the pipeline from running subsequent jobs, use `allow_failure: false`.

When jobs are allowed to fail (`allow_failure: true`) an orange warning (**{status_warning}**)
indicates that a job failed. However, the pipeline is successful and the associated commit
is marked as passed with no warnings.

This same warning is displayed when:

- All other jobs in the stage are successful.
- All other jobs in the pipeline are successful.

The default value for `allow_failure` is:

- `true` for [manual jobs](../jobs/job_control.md#create-a-job-that-must-be-run-manually).
- `false` for jobs that use `when: manual` inside [`rules`](#rules).
- `false` in all other cases.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `true` or `false`.

**Example of `allow_failure`**:

```yaml
job1:
  stage: test
  script:
    - execute_script_1

job2:
  stage: test
  script:
    - execute_script_2
  allow_failure: true

job3:
  stage: deploy
  script:
    - deploy_to_staging
  environment: staging
```

In this example, `job1` and `job2` run in parallel:

- If `job1` fails, jobs in the `deploy` stage do not start.
- If `job2` fails, jobs in the `deploy` stage can still start.

**Additional details**:

- You can use `allow_failure` as a subkey of [`rules`](#rulesallow_failure).
- If `allow_failure: true` is set, the job is always considered successful, and later jobs with [`when: on_failure`](#when) don't start if this job fails.
- You can use `allow_failure: false` with a manual job to create a [blocking manual job](../jobs/job_control.md#types-of-manual-jobs).
  A blocked pipeline does not run any jobs in later stages until the manual job
  is started and completes successfully.

#### `allow_failure:exit_codes`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/273157) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/292024) in GitLab 13.9.

Use `allow_failure:exit_codes` to control when a job should be
allowed to fail. The job is `allow_failure: true` for any of the listed exit codes,
and `allow_failure` false for any other exit code.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A single exit code.
- An array of exit codes.

**Example of `allow_failure`**:

```yaml
test_job_1:
  script:
    - echo "Run a script that results in exit code 1. This job fails."
    - exit 1
  allow_failure:
    exit_codes: 137

test_job_2:
  script:
    - echo "Run a script that results in exit code 137. This job is allowed to fail."
    - exit 137
  allow_failure:
    exit_codes:
      - 137
      - 255
```

### `artifacts`

Use `artifacts` to specify which files to save as [job artifacts](../jobs/job_artifacts.md).
Job artifacts are a list of files and directories that are
attached to the job when it [succeeds, fails, or always](#artifactswhen).

The artifacts are sent to GitLab after the job finishes. They are
available for download in the GitLab UI if the size is smaller than the
the [maximum artifact size](../../user/gitlab_com/index.md#gitlab-cicd).

By default, jobs in later stages automatically download all the artifacts created
by jobs in earlier stages. You can control artifact download behavior in jobs with
[`dependencies`](#dependencies).

When using the [`needs`](#needs) keyword, jobs can only download
artifacts from the jobs defined in the `needs` configuration.

Job artifacts are only collected for successful jobs by default, and
artifacts are restored after [caches](#cache).

[Read more about artifacts](../jobs/job_artifacts.md).

#### `artifacts:paths`

Paths are relative to the project directory (`$CI_PROJECT_DIR`) and can't directly
link outside it.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- An array of file paths, relative to the project directory.
- You can use Wildcards that use [glob](https://en.wikipedia.org/wiki/Glob_(programming))
  patterns and:
  - In [GitLab Runner 13.0 and later](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620),
    [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match).
  - In GitLab Runner 12.10 and earlier, [`filepath.Match`](https://pkg.go.dev/path/filepath#Match).

**Example of `artifacts:paths`**:

```yaml
job:
  artifacts:
    paths:
      - binaries/
      - .config
```

This example creates an artifact with `.config` and all the files in the `binaries` directory.

**Additional details**:

- If not used with [`artifacts:name`](#artifactsname), the artifacts file
  is named `artifacts`, which becomes `artifacts.zip` when downloaded.

**Related topics**:

- To restrict which jobs a specific job fetches artifacts from, see [`dependencies`](#dependencies).
- [Create job artifacts](../jobs/job_artifacts.md#create-job-artifacts).

#### `artifacts:exclude`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15122) in GitLab 13.1
> - Requires GitLab Runner 13.1

Use `artifacts:exclude` to prevent files from being added to an artifacts archive.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- An array of file paths, relative to the project directory.
- You can use Wildcards that use [glob](https://en.wikipedia.org/wiki/Glob_(programming)) or
  [`doublestar.PathMatch`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#PathMatch) patterns.

**Example of `artifacts:exclude`**:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

This example stores all files in `binaries/`, but not `*.o` files located in
subdirectories of `binaries/`.

**Additional details**:

- `artifacts:exclude` paths are not searched recursively.
- Files matched by [`artifacts:untracked`](#artifactsuntracked) can be excluded using
  `artifacts:exclude` too.

**Related topics**:

- [Exclude files from job artifacts](../jobs/job_artifacts.md#without-excluded-files).

#### `artifacts:expire_in`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16267) in GitLab 13.0 behind a disabled feature flag, the latest job artifacts are kept regardless of expiry time.
> - [Made default behavior](https://gitlab.com/gitlab-org/gitlab/-/issues/229936) in GitLab 13.4.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/241026) in GitLab 13.8, keeping latest job artifacts can be disabled at the project level.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276583) in GitLab 13.9, keeping latest job artifacts can be disabled instance-wide.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/321323) in GitLab 13.12, the latest pipeline artifacts are kept regardless of expiry time.

Use `expire_in` to specify how long [job artifacts](../jobs/job_artifacts.md) are stored before
they expire and are deleted. The `expire_in` setting does not affect:

- Artifacts from the latest job, unless keeping the latest job artifacts is disabled
  [at the project level](../jobs/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs).
  or [instance-wide](../../user/admin_area/settings/continuous_integration.md#keep-the-latest-artifacts-for-all-jobs-in-the-latest-successful-pipelines).
- [Pipeline artifacts](../pipelines/pipeline_artifacts.md). You can't specify an expiration date for
  pipeline artifacts. See [When pipeline artifacts are deleted](../pipelines/pipeline_artifacts.md#when-pipeline-artifacts-are-deleted)
  for more information.

After their expiry, artifacts are deleted hourly by default (using a cron job), and are not
accessible anymore.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**: The expiry time. If no unit is provided, the time is in seconds.
Valid values include:

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

**Example of `artifacts:expire_in`**:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

**Additional details**:

- The expiration time period begins when the artifact is uploaded and stored on GitLab.
  If the expiry time is not defined, it defaults to the [instance wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration).
- To override the expiration date and protect artifacts from being automatically deleted:
  - Select **Keep** on the job page.
  - [In GitLab 13.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/22761), set the value of
    `expire_in` to `never`.

#### `artifacts:expose_as`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15018) in GitLab 12.5.

Use the `artifacts:expose_as` keyword to
[expose job artifacts in the merge request UI](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui).

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- The name to display in the merge request UI for the artifacts download link.
  Must be combined with [`artifacts:paths`](#artifactspaths).

**Example of `artifacts:expose_as`**:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

**Additional details**:

- If `artifacts:paths` uses [CI/CD variables](../variables/index.md), the artifacts do not display in the UI.
- A maximum of 10 job artifacts per merge request can be exposed.
- Glob patterns are unsupported.
- If a directory is specified and there is more than one file in the directory,
  the link is to the job [artifacts browser](../jobs/job_artifacts.md#download-job-artifacts).
- If [GitLab Pages](../../administration/pages/index.md) is enabled, GitLab automatically
  renders the artifacts when the artifacts is a single file with one of these extensions:
  - `.html` or `.htm`
  - `.txt`
  - `.json`
  - `.xml`
  - `.log`

**Related topics**:

- [Expose job artifacts in the merge request UI](../jobs/job_artifacts.md#link-to-job-artifacts-in-the-merge-request-ui).

#### `artifacts:name`

Use the `artifacts:name` keyword to define the name of the created artifacts
archive. You can specify a unique name for every archive.

If not defined, the default name is `artifacts`, which becomes `artifacts.zip` when downloaded.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- The name of the artifacts archive. CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
  Must be combined with [`artifacts:paths`](#artifactspaths).

**Example of `artifacts:name`**:

To create an archive with a name of the current job:

```yaml
job:
  artifacts:
    name: "job1-artifacts-file"
    paths:
      - binaries/
```

**Related topics**:

- [Use CI/CD variables to define the artifacts name](../jobs/job_artifacts.md#with-a-dynamically-defined-name).

#### `artifacts:public`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/223273) in GitLab 13.8 [with a flag](../../user/feature_flags.md) named `non_public_artifacts`, disabled by default.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/322454) in GitLab 15.10. Artifacts created with `artifacts:public` before 15.10 are not guaranteed to remain private after this update.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../../administration/feature_flags.md) named `non_public_artifacts`. On
GitLab.com, this feature is not available.

Use `artifacts:public` to determine whether the job artifacts should be
publicly available.

When `artifacts:public` is `true` (default), the artifacts in
public pipelines are available for download by anonymous and guest users.

To deny read access for anonymous and guest users to artifacts in public
pipelines, set `artifacts:public` to `false`:

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `true` (default if not defined) or `false`.

**Example of `artifacts:public`**:

```yaml
job:
  artifacts:
    public: false
```

#### `artifacts:reports`

Use [`artifacts:reports`](artifacts_reports.md) to collect artifacts generated by
included templates in jobs.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- See list of available [artifacts reports types](artifacts_reports.md).

**Example of `artifacts:reports`**:

```yaml
rspec:
  stage: test
  script:
    - bundle install
    - rspec --format RspecJunitFormatter --out rspec.xml
  artifacts:
    reports:
      junit: rspec.xml
```

**Additional details**:

- Combining reports in parent pipelines using [artifacts from child pipelines](#needspipelinejob) is
  not supported. Track progress on adding support in [this issue](https://gitlab.com/gitlab-org/gitlab/-/issues/215725).
- To be able to browse the report output files, include the [`artifacts:paths`](#artifactspaths) keyword. This uploads and stores the artifact twice.
- Artifacts created for `artifacts: reports` are always uploaded, regardless of the job results (success or failure).
  You can use [`artifacts:expire_in`](#artifactsexpire_in) to set an expiration
  date for the artifacts.

#### `artifacts:untracked`

Use `artifacts:untracked` to add all Git untracked files as artifacts (along
with the paths defined in `artifacts:paths`). `artifacts:untracked` ignores configuration
in the repository's `.gitignore`, so matching artifacts in `.gitignore` are included.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `true` or `false` (default if not defined).

**Example of `artifacts:untracked`**:

Save all Git untracked files:

```yaml
job:
  artifacts:
    untracked: true
```

**Related topics**:

- [Add untracked files to artifacts](../jobs/job_artifacts.md#with-untracked-files).

#### `artifacts:when`

Use `artifacts:when` to upload artifacts on job failure or despite the
failure.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `on_success` (default): Upload artifacts only when the job succeeds.
- `on_failure`: Upload artifacts only when the job fails.
- `always`: Always upload artifacts (except when jobs time out). For example, when
  [uploading artifacts](../testing/unit_test_reports.md#view-junit-screenshots-on-gitlab)
  required to troubleshoot failing tests.

**Example of `artifacts:when`**:

```yaml
job:
  artifacts:
    when: on_failure
```

**Additional details**:

- The artifacts created for [`artifacts:reports`](#artifactsreports) are always uploaded,
  regardless of the job results (success or failure). `artifacts:when` does not change this behavior.

### `before_script`

Use `before_script` to define an array of commands that should run before each job's
`script` commands, but after [artifacts](#artifacts) are restored.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**: An array including:

- Single line commands.
- Long commands [split over multiple lines](script.md#split-long-commands).
- [YAML anchors](yaml_optimization.md#yaml-anchors-for-scripts).

CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Example of `before_script`**:

```yaml
job:
  before_script:
    - echo "Execute this command before any 'script:' commands."
  script:
    - echo "This command executes after the job's 'before_script' commands."
```

**Additional details**:

- Scripts you specify in `before_script` are concatenated with any scripts you specify
  in the main [`script`](#script). The combined scripts execute together in a single shell.
- Using `before_script` at the top level, but not in the `default` section, [is deprecated](#globally-defined-image-services-cache-before_script-after_script).

**Related topics**:

- [Use `before_script` with `default`](script.md#set-a-default-before_script-or-after_script-for-all-jobs)
  to define a default array of commands that should run before the `script` commands in all jobs.
- You can [ignore non-zero exit codes](script.md#ignore-non-zero-exit-codes).
- [Use color codes with `before_script`](script.md#add-color-codes-to-script-output)
  to make job logs easier to review.
- [Create custom collapsible sections](../jobs/index.md#custom-collapsible-sections)
  to simplify job log output.

### `cache`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/330047) in GitLab 15.0, caches are not shared between protected and unprotected branches.

Use `cache` to specify a list of files and directories to
cache between jobs. You can only use paths that are in the local working copy.

Caches are:

- Shared between pipelines and jobs.
- By default, not shared between [protected](../../user/project/protected_branches.md) and unprotected branches.
- Restored before [artifacts](#artifacts).
- Limited to a maximum of four [different caches](../caching/index.md#use-multiple-caches).

You can [disable caching for specific jobs](../caching/index.md#disable-cache-for-specific-jobs),
for example to override:

- A default cache defined with [`default`](#default).
- The configuration for a job added with [`include`](#include).

For more information about caches, see [Caching in GitLab CI/CD](../caching/index.md).

#### `cache:paths`

Use the `cache:paths` keyword to choose which files or directories to cache.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- An array of paths relative to the project directory (`$CI_PROJECT_DIR`).
  You can use wildcards that use [glob](https://en.wikipedia.org/wiki/Glob_(programming))
  patterns:
  - In [GitLab Runner 13.0 and later](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620),
  [`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match).
  - In GitLab Runner 12.10 and earlier,
  [`filepath.Match`](https://pkg.go.dev/path/filepath#Match).

**Example of `cache:paths`**:

Cache all files in `binaries` that end in `.apk` and the `.config` file:

```yaml
rspec:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache
    paths:
      - binaries/*.apk
      - .config
```

**Additional details**:

- The `cache:paths` keyword includes files even if they are untracked or in your `.gitignore` file.

**Related topics**:

- See the [common `cache` use cases](../caching/index.md#common-use-cases-for-caches) for more
  `cache:paths` examples.

#### `cache:key`

Use the `cache:key` keyword to give each cache a unique identifying key. All jobs
that use the same cache key use the same cache, including in different pipelines.

If not set, the default key is `default`. All jobs with the `cache` keyword but
no `cache:key` share the `default` cache.

Must be used with `cache: paths`, or nothing is cached.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- A string.
- A predefined [CI/CD variable](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).
- A combination of both.

**Example of `cache:key`**:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

**Additional details**:

- If you use **Windows Batch** to run your shell scripts you must replace
  `$` with `%`. For example: `key: %CI_COMMIT_REF_SLUG%`
- The `cache:key` value can't contain:

  - The `/` character, or the equivalent URI-encoded `%2F`.
  - Only the `.` character (any number), or the equivalent URI-encoded `%2E`.

- The cache is shared between jobs, so if you're using different
  paths for different jobs, you should also set a different `cache:key`.
  Otherwise cache content can be overwritten.

**Related topics**:

- You can specify a [fallback cache key](../caching/index.md#use-a-fallback-cache-key)
  to use if the specified `cache:key` is not found.
- You can [use multiple cache keys](../caching/index.md#use-multiple-caches) in a single job.
- See the [common `cache` use cases](../caching/index.md#common-use-cases-for-caches) for more
  `cache:key` examples.

##### `cache:key:files`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18986) in GitLab 12.5.

Use the `cache:key:files` keyword to generate a new key when one or two specific files
change. `cache:key:files` lets you reuse some caches, and rebuild them less often,
which speeds up subsequent pipeline runs.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- An array of one or two file paths.

**Example of `cache:key:files`**:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
        - package.json
    paths:
      - vendor/ruby
      - node_modules
```

This example creates a cache for Ruby and Node.js dependencies. The cache
is tied to the current versions of the `Gemfile.lock` and `package.json` files. When one of
these files changes, a new cache key is computed and a new cache is created. Any future
job runs that use the same `Gemfile.lock` and `package.json` with `cache:key:files`
use the new cache, instead of rebuilding the dependencies.

**Additional details**:

- The cache `key` is a SHA computed from the most recent commits
that changed each listed file.
  If neither file is changed in any commits, the fallback key is `default`.

##### `cache:key:prefix`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18986) in GitLab 12.5.

Use `cache:key:prefix` to combine a prefix with the SHA computed for [`cache:key:files`](#cachekeyfiles).

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- A string
- A [predefined variables](../variables/index.md)
- A combination of both.

**Example of `cache:key:prefix`**:

```yaml
rspec:
  script:
    - echo "This rspec job uses a cache."
  cache:
    key:
      files:
        - Gemfile.lock
      prefix: $CI_JOB_NAME
    paths:
      - vendor/ruby
```

For example, adding a `prefix` of `$CI_JOB_NAME` causes the key to look like `rspec-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5`.
If a branch changes `Gemfile.lock`, that branch has a new SHA checksum for `cache:key:files`.
A new cache key is generated, and a new cache is created for that key. If `Gemfile.lock`
is not found, the prefix is added to `default`, so the key in the example would be `rspec-default`.

**Additional details**:

- If no file in `cache:key:files` is changed in any commits, the prefix is added to the `default` key.

#### `cache:untracked`

Use `untracked: true` to cache all files that are untracked in your Git repository.
Untracked files include files that are:

- Ignored due to [`.gitignore` configuration](https://git-scm.com/docs/gitignore).
- Created, but not added to the checkout with [`git add`](https://git-scm.com/docs/git-add).

Caching untracked files can create unexpectedly large caches if the job downloads:

- Dependencies, like gems or node modules, which are usually untracked.
- [Artifacts](#artifacts) from a different job. Files extracted from the artifacts are untracked by default.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `true` or `false` (default).

**Example of `cache:untracked`**:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

**Additional details**:

- You can combine `cache:untracked` with `cache:paths` to cache all untracked files, as well as files in the configured paths.
  Use `cache:paths` to cache any specific files, including tracked files, or files that are outside of the working directory,
  and use `cache: untracked` to also cache all untracked files. For example:

  ```yaml
  rspec:
    script: test
    cache:
      untracked: true
      paths:
        - binaries/
  ```

  In this example, the job caches all untracked files in the repository, as well as all the files in `binaries/`.
  If there are untracked files in `binaries/`, they are covered by both keywords.

#### `cache:unprotect`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362114) in GitLab 15.8.

Use `cache:unprotect` to set a cache to be shared between [protected](../../user/project/protected_branches.md)
and unprotected branches.

WARNING:
When set to `true`, users without access to protected branches can read and write to
cache keys used by protected branches.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `true` or `false` (default).

**Example of `cache:unprotect`**:

```yaml
rspec:
  script: test
  cache:
    unprotect: true
```

#### `cache:when`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18969) in GitLab 13.5 and GitLab Runner v13.5.0.

Use `cache:when` to define when to save the cache, based on the status of the job.

Must be used with `cache: paths`, or nothing is cached.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `on_success` (default): Save the cache only when the job succeeds.
- `on_failure`: Save the cache only when the job fails.
- `always`: Always save the cache.

**Example of `cache:when`**:

```yaml
rspec:
  script: rspec
  cache:
    paths:
      - rspec/
    when: 'always'
```

This example stores the cache whether or not the job fails or succeeds.

#### `cache:policy`

To change the upload and download behavior of a cache, use the `cache:policy` keyword.
By default, the job downloads the cache when the job starts, and uploads changes
to the cache when the job ends. This caching style is the `pull-push` policy (default).

To set a job to only download the cache when the job starts, but never upload changes
when the job finishes, use `cache:policy:pull`.

To set a job to only upload a cache when the job finishes, but never download the
cache when the job starts, use `cache:policy:push`.

Use the `pull` policy when you have many jobs executing in parallel that use the same cache.
This policy speeds up job execution and reduces load on the cache server. You can
use a job with the `push` policy to build the cache.

Must be used with `cache: paths`, or nothing is cached.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `pull`
- `push`
- `pull-push` (default)

**Example of `cache:policy`**:

```yaml
prepare-dependencies-job:
  stage: build
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: push
  script:
    - echo "This job only downloads dependencies and builds the cache."
    - echo "Downloading dependencies..."

faster-test-job:
  stage: test
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: pull
  script:
    - echo "This job script uses the cache, but does not update it."
    - echo "Running tests..."
```

### `coverage`

Use `coverage` with a custom regular expression to configure how code coverage
is extracted from the job output. The coverage is shown in the UI if at least one
line in the job output matches the regular expression.

To extract the code coverage value from the match, GitLab uses
this smaller regular expression: `\d+(\.\d+)?`.

**Possible inputs**:

- A regular expression. Must start and end with `/`. Must match the coverage number.
  May match surrounding text as well, so you don't need to use a regular expression character group
  to capture the exact number.

**Example of `coverage`**:

```yaml
job1:
  script: rspec
  coverage: '/Code coverage: \d+\.\d+/'
```

In this example:

1. GitLab checks the job log for a match with the regular expression. A line
   like `Code coverage: 67.89% of lines covered` would match.
1. GitLab then checks the matched fragment to find a match to `\d+(\.\d+)?`.
   The sample matching line above gives a code coverage of `67.89`.

**Additional details**:

- You can find parse examples in [Code Coverage](../testing/code_coverage.md#test-coverage-examples).
- If there is more than one matched line in the job output, the last line is used
  (the first result of reverse search).
- If there are multiple matches in a single line, the last match is searched
  for the coverage number.
- If there are multiple coverage numbers found in the matched fragment, the first number is used.
- Leading zeros are removed.
- Coverage output from [child pipelines](../pipelines/downstream_pipelines.md#parent-child-pipelines)
  is not recorded or displayed. Check [the related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/280818)
  for more details.

### `dast_configuration` **(ULTIMATE)**

> [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/5981) in GitLab 14.1.

Use the `dast_configuration` keyword to specify a site profile and scanner profile to be used in a
CI/CD configuration. Both profiles must first have been created in the project. The job's stage must
be `dast`.

**Keyword type**: Job keyword. You can use only as part of a job.

**Possible inputs**: One each of `site_profile` and `scanner_profile`.

- Use `site_profile` to specify the site profile to be used in the job.
- Use `scanner_profile` to specify the scanner profile to be used in the job.

**Example of `dast_configuration`**:

```yaml
stages:
  - build
  - dast

include:
  - template: DAST.gitlab-ci.yml

dast:
  dast_configuration:
    site_profile: "Example Co"
    scanner_profile: "Quick Passive Test"
```

In this example, the `dast` job extends the `dast` configuration added with the `include` keyword
to select a specific site profile and scanner profile.

**Additional details**:

- Settings contained in either a site profile or scanner profile take precedence over those
  contained in the DAST template.

**Related topics**:

- [Site profile](../../user/application_security/dast/proxy-based.md#site-profile).
- [Scanner profile](../../user/application_security/dast/proxy-based.md#scanner-profile).

### `dependencies`

Use the `dependencies` keyword to define a list of jobs to fetch [artifacts](#artifacts) from.
You can also set a job to download no artifacts at all.

If you do not use `dependencies`, all artifacts from previous stages are passed to each job.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- The names of jobs to fetch artifacts from.
- An empty array (`[]`), to configure the job to not download any artifacts.

**Example of `dependencies`**:

```yaml
build osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
      - binaries/

build linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
      - binaries/

test osx:
  stage: test
  script: make test:osx
  dependencies:
    - build osx

test linux:
  stage: test
  script: make test:linux
  dependencies:
    - build linux

deploy:
  stage: deploy
  script: make deploy
  environment: production
```

In this example, two jobs have artifacts: `build osx` and `build linux`. When `test osx` is executed,
the artifacts from `build osx` are downloaded and extracted in the context of the build.
The same thing happens for `test linux` and artifacts from `build linux`.

The `deploy` job downloads artifacts from all previous jobs because of
the [stage](#stages) precedence.

**Additional details**:

- The job status does not matter. If a job fails or it's a manual job that isn't triggered, no error occurs.
- If the artifacts of a dependent job are [expired](#artifactsexpire_in) or
  [deleted](../jobs/job_artifacts.md#delete-job-log-and-artifacts), then the job fails.

### `environment`

Use `environment` to define the [environment](../environments/index.md) that a job deploys to.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: The name of the environment the job deploys to, in one of these
formats:

- Plain text, including letters, digits, spaces, and these characters: `-`, `_`, `/`, `$`, `{`, `}`.
- CI/CD variables, including predefined, project, group, instance, or variables defined in the
  `.gitlab-ci.yml` file. You can't use variables defined in a `script` section.

**Example of `environment`**:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment: production
```

**Additional details**:

- If you specify an `environment` and no environment with that name exists, an environment is
  created.

#### `environment:name`

Set a name for an [environment](../environments/index.md).

Common environment names are `qa`, `staging`, and `production`, but you can use any name.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: The name of the environment the job deploys to, in one of these
formats:

- Plain text, including letters, digits, spaces, and these characters: `-`, `_`, `/`, `$`, `{`, `}`.
- [CI/CD variables](../variables/where_variables_can_be_used.md#gitlab-ciyml-file),
  including predefined, project, group, instance, or variables defined in the
  `.gitlab-ci.yml` file. You can't use variables defined in a `script` section.

**Example of `environment:name`**:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
```

#### `environment:url`

Set a URL for an [environment](../environments/index.md).

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: A single URL, in one of these formats:

- Plain text, like `https://prod.example.com`.
- [CI/CD variables](../variables/where_variables_can_be_used.md#gitlab-ciyml-file),
  including predefined, project, group, instance, or variables defined in the
  `.gitlab-ci.yml` file. You can't use variables defined in a `script` section.

**Example of `environment:url`**:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
    url: https://prod.example.com
```

**Additional details**:

- After the job completes, you can access the URL by selecting a button in the merge request,
  environment, or deployment pages.

#### `environment:on_stop`

Closing (stopping) environments can be achieved with the `on_stop` keyword
defined under `environment`. It declares a different job that runs to close the
environment.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Additional details**:

- See [`environment:action`](#environmentaction) for more details and an example.

#### `environment:action`

Use the `action` keyword to specify how the job interacts with the environment.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: One of the following keywords:

| **Value** | **Description** |
|:----------|:----------------|
| `start`   | Default value. Indicates that the job starts the environment. The deployment is created after the job starts. |
| `prepare` | Indicates that the job is only preparing the environment. It does not trigger deployments. [Read more about preparing environments](../environments/index.md#access-an-environment-for-preparation-or-verification-purposes). |
| `stop`    | Indicates that the job stops an environment. [Read more about stopping an environment](../environments/index.md#stopping-an-environment). |
| `verify`  | Indicates that the job is only verifying the environment. It does not trigger deployments. [Read more about verifying environments](../environments/index.md#access-an-environment-for-preparation-or-verification-purposes). |
| `access`  | Indicates that the job is only accessing the environment. It does not trigger deployments. [Read more about accessing environments](../environments/index.md#access-an-environment-for-preparation-or-verification-purposes). |

**Example of `environment:action`**:

```yaml
stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    action: stop
```

#### `environment:auto_stop_in`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20956) in GitLab 12.8.

The `auto_stop_in` keyword specifies the lifetime of the environment. When an environment expires, GitLab
automatically stops it.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: A period of time written in natural language. For example,
these are all equivalent:

- `168 hours`
- `7 days`
- `one week`
- `never`

**Example of `environment:auto_stop_in`**:

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    auto_stop_in: 1 day
```

When the environment for `review_app` is created, the environment's lifetime is set to `1 day`.
Every time the review app is deployed, that lifetime is also reset to `1 day`.

**Related topics**:

- [Environments auto-stop documentation](../environments/index.md#stop-an-environment-after-a-certain-time-period).

#### `environment:kubernetes`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27630) in GitLab 12.6.

Use the `kubernetes` keyword to configure deployments to a
[Kubernetes cluster](../../user/infrastructure/clusters/index.md) that is associated with your project.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Example of `environment:kubernetes`**:

```yaml
deploy:
  stage: deploy
  script: make deploy-app
  environment:
    name: production
    kubernetes:
      namespace: production
```

This configuration sets up the `deploy` job to deploy to the `production`
environment, using the `production`
[Kubernetes namespace](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/).

**Additional details**:

- Kubernetes configuration is not supported for Kubernetes clusters
  [managed by GitLab](../../user/project/clusters/gitlab_managed_clusters.md).

**Related topics**:

- [Available settings for `kubernetes`](../environments/index.md#configure-kubernetes-deployments-deprecated).

#### `environment:deployment_tier`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300741) in GitLab 13.10.

Use the `deployment_tier` keyword to specify the tier of the deployment environment.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: One of the following:

- `production`
- `staging`
- `testing`
- `development`
- `other`

**Example of `environment:deployment_tier`**:

```yaml
deploy:
  script: echo
  environment:
    name: customer-portal
    deployment_tier: production
```

**Additional details**:

- Environments created from this job definition are assigned a [tier](../environments/index.md#deployment-tier-of-environments) based on this value.
- Existing environments don't have their tier updated if this value is added later. Existing environments must have their tier updated via the [Environments API](../../api/environments.md#update-an-existing-environment).

**Related topics**:

- [Deployment tier of environments](../environments/index.md#deployment-tier-of-environments).

#### Dynamic environments

Use CI/CD [variables](../variables/index.md) to dynamically name environments.

For example:

```yaml
deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
```

The `deploy as review app` job is marked as a deployment to dynamically
create the `review/$CI_COMMIT_REF_SLUG` environment. `$CI_COMMIT_REF_SLUG`
is a [CI/CD variable](../variables/index.md) set by the runner. The
`$CI_ENVIRONMENT_SLUG` variable is based on the environment name, but suitable
for inclusion in URLs. If the `deploy as review app` job runs in a branch named
`pow`, this environment would be accessible with a URL like `https://review-pow.example.com/`.

The common use case is to create dynamic environments for branches and use them
as Review Apps. You can see an example that uses Review Apps at
<https://gitlab.com/gitlab-examples/review-apps-nginx/>.

### `extends`

Use `extends` to reuse configuration sections. It's an alternative to [YAML anchors](yaml_optimization.md#anchors)
and is a little more flexible and readable.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- The name of another job in the pipeline.
- A list (array) of names of other jobs in the pipeline.

**Example of `extends`**:

```yaml
.tests:
  script: rake test
  stage: test
  only:
    refs:
      - branches

rspec:
  extends: .tests
  script: rake rspec
  only:
    variables:
      - $RSPEC
```

In this example, the `rspec` job uses the configuration from the `.tests` template job.
When creating the pipeline, GitLab:

- Performs a reverse deep merge based on the keys.
- Merges the `.tests` content with the `rspec` job.
- Doesn't merge the values of the keys.

The result is this `rspec` job:

```yaml
rspec:
  script: rake rspec
  stage: test
  only:
    refs:
      - branches
    variables:
      - $RSPEC
```

**Additional details**:

- In GitLab 12.0 and later, you can use multiple parents for `extends`.
- The `extends` keyword supports up to eleven levels of inheritance, but you should
  avoid using more than three levels.
- In the example above, `.tests` is a [hidden job](../jobs/index.md#hide-jobs),
  but you can extend configuration from regular jobs as well.

**Related topics**:

- [Reuse configuration sections by using `extends`](yaml_optimization.md#use-extends-to-reuse-configuration-sections).
- Use `extends` to reuse configuration from [included configuration files](yaml_optimization.md#use-extends-and-include-together).

### `hooks`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356850) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/381840) in GitLab 15.10. Feature flag `ci_hooks_pre_get_sources_script` removed.

Use `hooks` to specify lists of commands to execute on the runner
at certain stages of job execution, like before retrieving the Git repository.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- A hash of hooks and their commands. Available hooks: `pre_get_sources_script`.

#### `hooks:pre_get_sources_script`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356850) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_hooks_pre_get_sources_script`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/381840) in GitLab 15.10. Feature flag `ci_hooks_pre_get_sources_script` removed.

Use `hooks:pre_get_sources_script` to specify a list of commands to execute on the runner
before retrieving the Git repository and any submodules. You can use it
to adjust the Git client configuration first, for example.

**Related topics**:

- [GitLab Runner configuration](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-runners-section)

**Example of `hooks:pre_get_sources_script`**:

```yaml
job1:
  hooks:
    pre_get_sources_script:
      - echo 'hello job1 pre_get_sources_script'
  script: echo 'hello job1 script'
```

### `id_tokens`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356986) in GitLab 15.7.

Use `id_tokens` to create [JSON web tokens (JWT)](https://www.rfc-editor.org/rfc/rfc7519) to authenticate with third party services. All
JWTs created this way support OIDC authentication. The required `aud` sub-keyword is used to configure the `aud` claim for the JWT.

**Possible inputs**:

- Token names with their `aud` claims. `aud` can be a single string or as an array of strings.

**Example of `id_tokens`**:

```yaml
job_with_id_tokens:
  id_tokens:
    ID_TOKEN_1:
      aud: https://gitlab.com
    ID_TOKEN_2:
      aud:
        - https://gcp.com
        - https://aws.com
  script:
    - command_to_authenticate_with_gitlab $ID_TOKEN_1
    - command_to_authenticate_with_aws $ID_TOKEN_2
```

### `image`

Use `image` to specify a Docker image that the job runs in.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**: The name of the image, including the registry path if needed, in one of these formats:

- `<image-name>` (Same as using `<image-name>` with the `latest` tag)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Example of `image`**:

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: registry.example.com/my-group/my-project/ruby:2.7
  script: bundle exec rspec
```

In this example, the `ruby:3.0` image is the default for all jobs in the pipeline.
The `rspec 2.7` job does not use the default, because it overrides the default with
a job-specific `image` section.

**Related topics**:

- [Run your CI/CD jobs in Docker containers](../docker/using_docker_images.md).

#### `image:name`

The name of the Docker image that the job runs in. Similar to [`image`](#image) used by itself.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**: The name of the image, including the registry path if needed, in one of these formats:

- `<image-name>` (Same as using `<image-name>` with the `latest` tag)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

**Example of `image:name`**:

```yaml
image:
  name: "registry.example.com/my/image:latest"
```

**Related topics**:

- [Run your CI/CD jobs in Docker containers](../docker/using_docker_images.md).

#### `image:entrypoint`

Command or script to execute as the container's entry point.

When the Docker container is created, the `entrypoint` is translated to the Docker `--entrypoint` option.
The syntax is similar to the [Dockerfile `ENTRYPOINT` directive](https://docs.docker.com/engine/reference/builder/#entrypoint),
where each shell token is a separate string in the array.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- A string.

**Example of `image:entrypoint`**:

```yaml
image:
  name: super/sql:experimental
  entrypoint: [""]
```

**Related topics**:

- [Override the entrypoint of an image](../docker/using_docker_images.md#override-the-entrypoint-of-an-image).

#### `image:pull_policy`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21619) in GitLab 15.1 [with a flag](../../administration/feature_flags.md) named `ci_docker_image_pull_policy`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) in GitLab 15.2.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) in GitLab 15.4. [Feature flag `ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) removed.
> - Requires GitLab Runner 15.1 or later.

The pull policy that the runner uses to fetch the Docker image.

**Keyword type**: Job keyword. You can use it only as part of a job or in the [`default` section](#default).

**Possible inputs**:

- A single pull policy, or multiple pull policies in an array.
  Can be `always`, `if-not-present`, or `never`.

**Examples of `image:pull_policy`**:

```yaml
job1:
  script: echo "A single pull policy."
  image:
    name: ruby:3.0
    pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  image:
    name: ruby:3.0
    pull_policy: [always, if-not-present]
```

**Additional details**:

- If the runner does not support the defined pull policy, the job fails with an error similar to:
  `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`.

**Related topics**:

- [Run your CI/CD jobs in Docker containers](../docker/using_docker_images.md).
- [How runner pull policies work](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work).
- [Using multiple pull policies](https://docs.gitlab.com/runner/executors/docker.html#using-multiple-pull-policies).

### `inherit`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207484) in GitLab 12.9.

Use `inherit` to [control inheritance of default keywords and variables](../jobs/index.md#control-the-inheritance-of-default-keywords-and-global-variables).

#### `inherit:default`

Use `inherit:default` to control the inheritance of [default keywords](#default).

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `true` (default) or `false` to enable or disable the inheritance of all default keywords.
- A list of specific default keywords to inherit.

**Example of `inherit:default`**:

```yaml
default:
  retry: 2
  image: ruby:3.0
  interruptible: true

job1:
  script: echo "This job does not inherit any default keywords."
  inherit:
    default: false

job2:
  script: echo "This job inherits only the two listed default keywords. It does not inherit 'interruptible'."
  inherit:
    default:
      - retry
      - image
```

**Additional details**:

- You can also list default keywords to inherit on one line: `default: [keyword1, keyword2]`

#### `inherit:variables`

Use `inherit:variables` to control the inheritance of [global variables](#variables) keywords.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `true` (default) or `false` to enable or disable the inheritance of all global variables.
- A list of specific variables to inherit.

**Example of `inherit:variables`**:

```yaml
variables:
  VARIABLE1: "This is variable 1"
  VARIABLE2: "This is variable 2"
  VARIABLE3: "This is variable 3"

job1:
  script: echo "This job does not inherit any global variables."
  inherit:
    variables: false

job2:
  script: echo "This job inherits only the two listed global variables. It does not inherit 'VARIABLE3'."
  inherit:
    variables:
      - VARIABLE1
      - VARIABLE2
```

**Additional details**:

- You can also list global variables to inherit on one line: `variables: [VARIABLE1, VARIABLE2]`

### `interruptible`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32022) in GitLab 12.3.

Use `interruptible` if a job should be canceled when a newer pipeline starts before the job completes.

This keyword has no effect if [automatic cancellation of redundant pipelines](../pipelines/settings.md#auto-cancel-redundant-pipelines)
is disabled. When enabled, a running job with `interruptible: true` is cancelled when
starting a pipeline for a new change on the same branch.

You can't cancel subsequent jobs after a job with `interruptible: false` starts.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `true` or `false` (default).

**Example of `interruptible`**:

```yaml
stages:
  - stage1
  - stage2
  - stage3

step-1:
  stage: stage1
  script:
    - echo "Can be canceled."
  interruptible: true

step-2:
  stage: stage2
  script:
    - echo "Can not be canceled."

step-3:
  stage: stage3
  script:
    - echo "Because step-2 can not be canceled, this step can never be canceled, even though it's set as interruptible."
  interruptible: true
```

In this example, a new pipeline causes a running pipeline to be:

- Canceled, if only `step-1` is running or pending.
- Not canceled, after `step-2` starts.

**Additional details**:

- Only set `interruptible: true` if the job can be safely canceled after it has started,
  like a build job. Deployment jobs usually shouldn't be cancelled, to prevent partial deployments.
- To completely cancel a running pipeline, all jobs must have `interruptible: true`,
  or `interruptible: false` jobs must not have started.

### `needs`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47063) in GitLab 12.2.
> - In GitLab 12.3, maximum number of jobs in `needs` array raised from five to 50.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30631) in GitLab 12.8, `needs: []` lets jobs start immediately.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30632) in GitLab 14.2, you can refer to jobs in the same stage as the job you are configuring.

Use `needs` to execute jobs out-of-order. Relationships between jobs
that use `needs` can be visualized as a [directed acyclic graph](../directed_acyclic_graph/index.md).

You can ignore stage ordering and run some jobs without waiting for others to complete.
Jobs in multiple stages can run concurrently.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- An array of jobs.
- An empty array (`[]`), to set the job to start as soon as the pipeline is created.

**Example of `needs`**:

```yaml
linux:build:
  stage: build
  script: echo "Building linux..."

mac:build:
  stage: build
  script: echo "Building mac..."

lint:
  stage: test
  needs: []
  script: echo "Linting..."

linux:rspec:
  stage: test
  needs: ["linux:build"]
  script: echo "Running rspec on linux..."

mac:rspec:
  stage: test
  needs: ["mac:build"]
  script: echo "Running rspec on mac..."

production:
  stage: deploy
  script: echo "Running production..."
  environment: production
```

This example creates four paths of execution:

- Linter: The `lint` job runs immediately without waiting for the `build` stage
  to complete because it has no needs (`needs: []`).
- Linux path: The `linux:rspec` job runs as soon as the `linux:build`
  job finishes, without waiting for `mac:build` to finish.
- macOS path: The `mac:rspec` jobs runs as soon as the `mac:build`
  job finishes, without waiting for `linux:build` to finish.
- The `production` job runs as soon as all previous jobs finish:
  `linux:build`, `linux:rspec`, `mac:build`, `mac:rspec`.

**Additional details**:

- The maximum number of jobs that a single job can have in the `needs` array is limited:
  - For GitLab.com, the limit is 50. For more information, see our
    [infrastructure issue](https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/7541).
  - For self-managed instances, the default limit is 50. This limit [can be changed](../../administration/cicd.md#set-the-needs-job-limit).
- If `needs` refers to a job that uses the [`parallel`](#parallel) keyword,
  it depends on all jobs created in parallel, not just one job. It also downloads
  artifacts from all the parallel jobs by default. If the artifacts have the same
  name, they overwrite each other and only the last one downloaded is saved.
- In [GitLab 14.1 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/30632) you
  can refer to jobs in the same stage as the job you are configuring. This feature is
  enabled on GitLab.com and ready for production use. On self-managed [GitLab 14.2 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/30632)
  this feature is available by default.
- In GitLab 14.0 and older, you can only refer to jobs in earlier stages. Stages must be
  explicitly defined for all jobs that use the `needs` keyword, or are referenced
  in a job's `needs` section.
- In GitLab 13.9 and older, if `needs` refers to a job that might not be added to
  a pipeline because of `only`, `except`, or `rules`, the pipeline might fail to create. In GitLab 13.10 and later, use the [`needs:optional`](#needsoptional) keyword to resolve a failed pipeline creation.
- If a pipeline has jobs with `needs: []` and jobs in the [`.pre`](#stage-pre) stage, they will
  all start as soon as the pipeline is created. Jobs with `needs: []` start immediately,
  and jobs in the `.pre` stage also start immediately.

#### `needs:artifacts`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14311) in GitLab 12.6.

When a job uses `needs`, it no longer downloads all artifacts from previous stages
by default, because jobs with `needs` can start before earlier stages complete. With
`needs` you can only download artifacts from the jobs listed in the `needs` configuration.

Use `artifacts: true` (default) or `artifacts: false` to control when artifacts are
downloaded in jobs that use `needs`.

**Keyword type**: Job keyword. You can use it only as part of a job. Must be used with `needs:job`.

**Possible inputs**:

- `true` (default) or `false`.

**Example of `needs:artifacts`**:

```yaml
test-job1:
  stage: test
  needs:
    - job: build_job1
      artifacts: true

test-job2:
  stage: test
  needs:
    - job: build_job2
      artifacts: false

test-job3:
  needs:
    - job: build_job1
      artifacts: true
    - job: build_job2
    - build_job3
```

In this example:

- The `test-job1` job downloads the `build_job1` artifacts
- The `test-job2` job does not download the `build_job2` artifacts.
- The `test-job3` job downloads the artifacts from all three `build_jobs`, because
  `artifacts` is `true`, or defaults to `true`, for all three needed jobs.

**Additional details**:

- In GitLab 12.6 and later, you can't combine the [`dependencies`](#dependencies) keyword
  with `needs`.

#### `needs:project` **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14311) in GitLab 12.7.

Use `needs:project` to download artifacts from up to five jobs in other pipelines.
The artifacts are downloaded from the latest successful specified job for the specified ref.
To specify multiple jobs, add each as separate array items under the `needs` keyword.

If there is a pipeline running for the ref, a job with `needs:project`
does not wait for the pipeline to complete. Instead, the artifacts are downloaded
from the latest successful run of the specified job.

`needs:project` must be used with `job`, `ref`, and `artifacts`.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `needs:project`: A full project path, including namespace and group.
- `job`: The job to download artifacts from.
- `ref`: The ref to download artifacts from.
- `artifacts`: Must be `true` to download artifacts.

**Examples of `needs:project`**:

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: namespace/group/project-name
      job: build-1
      ref: main
      artifacts: true
    - project: namespace/group/project-name-2
      job: build-2
      ref: main
      artifacts: true
```

In this example, `build_job` downloads the artifacts from the latest successful `build-1` and `build-2` jobs
on the `main` branches in the `group/project-name` and `group/project-name-2` projects.

In GitLab 13.3 and later, you can use [CI/CD variables](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
in `needs:project`, for example:

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: $CI_PROJECT_PATH
      job: $DEPENDENCY_JOB_NAME
      ref: $ARTIFACTS_DOWNLOAD_REF
      artifacts: true
```

**Additional details**:

- To download artifacts from a different pipeline in the current project, set `project`
  to be the same as the current project, but use a different ref than the current pipeline.
  Concurrent pipelines running on the same ref could override the artifacts.
- The user running the pipeline must have at least the Reporter role for the group or project,
  or the group/project must have public visibility.
- You can't use `needs:project` in the same job as [`trigger`](#trigger).
- When using `needs:project` to download artifacts from another pipeline, the job does not wait for
  the needed job to complete. [Directed acyclic graph](../directed_acyclic_graph/index.md)
  behavior is limited to jobs in the same pipeline. Make sure that the needed job in the other
  pipeline completes before the job that needs it tries to download the artifacts.
- You can't download artifacts from jobs that run in [`parallel`](#parallel).
- Support for [CI/CD variables](../variables/index.md) in `project`, `job`, and `ref` was
  [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202093) in GitLab 13.3.
  [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/235761) in GitLab 13.4.

**Related topics**:

- To download artifacts between [parent-child pipelines](../pipelines/downstream_pipelines.md#parent-child-pipelines),
  use [`needs:pipeline:job`](#needspipelinejob).

#### `needs:pipeline:job`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/255983) in GitLab 13.7.

A [child pipeline](../pipelines/downstream_pipelines.md#parent-child-pipelines) can download artifacts from a job in
its parent pipeline or another child pipeline in the same parent-child pipeline hierarchy.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `needs:pipeline`: A pipeline ID. Must be a pipeline present in the same parent-child pipeline hierarchy.
- `job`: The job to download artifacts from.

**Example of `needs:pipeline:job`**:

- Parent pipeline (`.gitlab-ci.yml`):

  ```yaml
  create-artifact:
    stage: build
    script: echo "sample artifact" > artifact.txt
    artifacts:
      paths: [artifact.txt]

  child-pipeline:
    stage: test
    trigger:
      include: child.yml
      strategy: depend
    variables:
      PARENT_PIPELINE_ID: $CI_PIPELINE_ID
  ```

- Child pipeline (`child.yml`):

  ```yaml
  use-artifact:
    script: cat artifact.txt
    needs:
      - pipeline: $PARENT_PIPELINE_ID
        job: create-artifact
  ```

In this example, the `create-artifact` job in the parent pipeline creates some artifacts.
The `child-pipeline` job triggers a child pipeline, and passes the `CI_PIPELINE_ID`
variable to the child pipeline as a new `PARENT_PIPELINE_ID` variable. The child pipeline
can use that variable in `needs:pipeline` to download artifacts from the parent pipeline.

**Additional details**:

- The `pipeline` attribute does not accept the current pipeline ID (`$CI_PIPELINE_ID`).
  To download artifacts from a job in the current pipeline, use [`needs`](#needsartifacts).

#### `needs:optional`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30680) in GitLab 13.10.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/323891) in GitLab 14.0.

To need a job that sometimes does not exist in the pipeline, add `optional: true`
to the `needs` configuration. If not defined, `optional: false` is the default.

Jobs that use [`rules`](#rules), [`only`, or `except`](#only--except) and that are added with [`include`](#include)
might not always be added to a pipeline. GitLab checks the `needs` relationships before starting a pipeline:

- If the `needs` entry has `optional: true` and the needed job is present in the pipeline,
  the job waits for it to complete before starting.
- If the needed job is not present, the job can start when all other needs requirements are met.
- If the `needs` section contains only optional jobs, and none are added to the pipeline,
  the job starts immediately (the same as an empty `needs` entry: `needs: []`).
- If a needed job has `optional: false`, but it was not added to the pipeline, the
  pipeline fails to start with an error similar to: `'job1' job needs 'job2' job, but it was not added to the pipeline`.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Example of `needs:optional`**:

```yaml
build-job:
  stage: build

test-job1:
  stage: test

test-job2:
  stage: test
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

deploy-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
    - job: test-job1
  environment: production

review-job:
  stage: deploy
  needs:
    - job: test-job2
      optional: true
  environment: review
```

In this example:

- `build-job`, `test-job1`, and `test-job2` start in stage order.
- When the branch is the default branch, `test-job2` is added to the pipeline, so:
  - `deploy-job` waits for both `test-job1` and `test-job2` to complete.
  - `review-job` waits for `test-job2` to complete.
- When the branch is not the default branch, `test-job2` is not added to the pipeline, so:
  - `deploy-job` waits for only `test-job1` to complete, and does not wait for the missing `test-job2`.
  - `review-job` has no other needed jobs and starts immediately (at the same time as `build-job`),
    like `needs: []`.

#### `needs:pipeline`

You can mirror the pipeline status from an upstream pipeline to a job by
using the `needs:pipeline` keyword. The latest pipeline status from the default branch is
replicated to the job.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A full project path, including namespace and group. If the
  project is in the same group or namespace, you can omit them from the `project`
  keyword. For example: `project: group/project-name` or `project: project-name`.

**Example of `needs:pipeline`**:

```yaml
upstream_status:
  stage: test
  needs:
    pipeline: other/project
```

**Additional details**:

- If you add the `job` keyword to `needs:pipeline`, the job no longer mirrors the
  pipeline status. The behavior changes to [`needs:pipeline:job`](#needspipelinejob).

### `only` / `except`

NOTE:
`only` and `except` are not being actively developed. [`rules`](#rules) is the preferred
keyword to control when to add jobs to pipelines.

You can use `only` and `except` to control when to add jobs to pipelines.

- Use `only` to define when a job runs.
- Use `except` to define when a job **does not** run.

See [specify when jobs run with `only` and `except`](../jobs/job_control.md#specify-when-jobs-run-with-only-and-except)
for more details and examples.

#### `only:refs` / `except:refs`

Use the `only:refs` and `except:refs` keywords to control when to add jobs to a
pipeline based on branch names or pipeline types.

`only:refs` and `except:refs` are not being actively developed. [`rules:if`](#rulesif)
is the preferred keyword when using refs, regular expressions, or variables to control
when to add jobs to pipelines.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array including any number of:

- Branch names, for example `main` or `my-feature-branch`.
- [Regular expressions](../jobs/job_control.md#only--except-regex-syntax)
  that match against branch names, for example `/^feature-.*/`.
- The following keywords:

  | **Value**                | **Description** |
  | -------------------------|-----------------|
  | `api`                    | For pipelines triggered by the [pipelines API](../../api/pipelines.md#create-a-new-pipeline). |
  | `branches`               | When the Git reference for a pipeline is a branch. |
  | `chat`                   | For pipelines created by using a [GitLab ChatOps](../chatops/index.md) command. |
  | `external`               | When you use CI services other than GitLab. |
  | `external_pull_requests` | When an external pull request on GitHub is created or updated (See [Pipelines for external pull requests](../ci_cd_for_external_repos/index.md#pipelines-for-external-pull-requests)). |
  | `merge_requests`         | For pipelines created when a merge request is created or updated. Enables [merge request pipelines](../pipelines/merge_request_pipelines.md), [merged results pipelines](../pipelines/merged_results_pipelines.md), and [merge trains](../pipelines/merge_trains.md). |
  | `pipelines`              | For [multi-project pipelines](../pipelines/downstream_pipelines.md#multi-project-pipelines) created by [using the API with `CI_JOB_TOKEN`](../pipelines/downstream_pipelines.md#trigger-a-multi-project-pipeline-by-using-the-api), or the [`trigger`](#trigger) keyword. |
  | `pushes`                 | For pipelines triggered by a `git push` event, including for branches and tags. |
  | `schedules`              | For [scheduled pipelines](../pipelines/schedules.md). |
  | `tags`                   | When the Git reference for a pipeline is a tag. |
  | `triggers`               | For pipelines created by using a [trigger token](../triggers/index.md#configure-cicd-jobs-to-run-in-triggered-pipelines). |
  | `web`                    | For pipelines created by selecting **Run pipeline** in the GitLab UI, from the project's **CI/CD > Pipelines** section. |

**Example of `only:refs` and `except:refs`**:

```yaml
job1:
  script: echo
  only:
    - main
    - /^issue-.*$/
    - merge_requests

job2:
  script: echo
  except:
    - main
    - /^stable-branch.*$/
    - schedules
```

**Additional details**:

- Scheduled pipelines run on specific branches, so jobs configured with `only: branches`
  run on scheduled pipelines too. Add `except: schedules` to prevent jobs with `only: branches`
  from running on scheduled pipelines.
- `only` or `except` used without any other keywords are equivalent to `only: refs`
  or `except: refs`. For example, the following two jobs configurations have the same
  behavior:

  ```yaml
  job1:
    script: echo
    only:
      - branches

  job2:
    script: echo
    only:
      refs:
        - branches
  ```

- If a job does not use `only`, `except`, or [`rules`](#rules), then `only` is set to `branches`
  and `tags` by default.

  For example, `job1` and `job2` are equivalent:

  ```yaml
  job1:
    script: echo "test"

  job2:
    script: echo "test"
    only:
      - branches
      - tags
  ```

#### `only:variables` / `except:variables`

Use the `only:variables` or `except:variables` keywords to control when to add jobs
to a pipeline, based on the status of [CI/CD variables](../variables/index.md).

`only:variables` and `except:variables` are not being actively developed. [`rules:if`](#rulesif)
is the preferred keyword when using refs, regular expressions, or variables to control
when to add jobs to pipelines.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- An array of [CI/CD variable expressions](../jobs/job_control.md#cicd-variable-expressions).

**Example of `only:variables`**:

```yaml
deploy:
  script: cap staging deploy
  only:
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

**Related topics**:

- [`only:variables` and `except:variables` examples](../jobs/job_control.md#only-variables--except-variables-examples).

#### `only:changes` / `except:changes`

Use the `changes` keyword with `only` to run a job, or with `except` to skip a job,
when a Git push event modifies a file.

Use `changes` in pipelines with the following refs:

- `branches`
- `external_pull_requests`
- `merge_requests` (see additional details about [using `only:changes` with merge request pipelines](../jobs/job_control.md#use-onlychanges-with-merge-request-pipelines))

`only:changes` and `except:changes` are not being actively developed. [`rules:changes`](#ruleschanges)
is the preferred keyword when using changed files to control when to add jobs to pipelines.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array including any number of:

- Paths to files.
- Wildcard paths for single directories, for example `path/to/directory/*`, or a directory
  and all its subdirectories, for example `path/to/directory/**/*`.
- Wildcard [glob](https://en.wikipedia.org/wiki/Glob_(programming)) paths for all
  files with the same extension or multiple extensions, for example `*.md` or `path/to/directory/*.{rb,py,sh}`.
  See the [Ruby `fnmatch` documentation](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)
  for the supported syntax list.
- Wildcard paths to files in the root directory, or all directories, wrapped in double quotes.
  For example `"*.json"` or `"**/*.json"`.

**Example of `only:changes`**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  only:
    refs:
      - branches
    changes:
      - Dockerfile
      - docker/scripts/*
      - dockerfiles/**/*
      - more_scripts/*.{rb,py,sh}
      - "**/*.json"
```

**Additional details**:

- `changes` resolves to `true` if any of the matching files are changed (an `OR` operation).
- If you use refs other than `branches`, `external_pull_requests`, or `merge_requests`,
  `changes` can't determine if a given file is new or old and always returns `true`.
- If you use `only: changes` with other refs, jobs ignore the changes and always run.
- If you use `except: changes` with other refs, jobs ignore the changes and never run.

**Related topics**:

- [`only: changes` and `except: changes` examples](../jobs/job_control.md#onlychanges--exceptchanges-examples).
- If you use `changes` with [only allow merge requests to be merged if the pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#require-a-successful-pipeline-for-merge),
  you should [also use `only:merge_requests`](../jobs/job_control.md#use-onlychanges-with-merge-request-pipelines).
- [Jobs or pipelines can run unexpectedly when using `only: changes`](../jobs/job_control.md#jobs-or-pipelines-run-unexpectedly-when-using-changes).

#### `only:kubernetes` / `except:kubernetes`

Use `only:kubernetes` or `except:kubernetes` to control if jobs are added to the pipeline
when the Kubernetes service is active in the project.

`only:refs` and `except:refs` are not being actively developed. Use [`rules:if`](#rulesif)
with the [`CI_KUBERNETES_ACTIVE`](../variables/predefined_variables.md) predefined CI/CD variable
to control if jobs are added to the pipeline when the Kubernetes service is active in the project.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**:

- The `kubernetes` strategy accepts only the `active` keyword.

**Example of `only:kubernetes`**:

```yaml
deploy:
  only:
    kubernetes: active
```

In this example, the `deploy` job runs only when the Kubernetes service is active
in the project.

### `pages`

Use `pages` to define a [GitLab Pages](../../user/project/pages/index.md) job that
uploads static content to GitLab. The content is then published as a website.

**Keyword type**: Job name.

**Example of `pages`**:

```yaml
pages:
  stage: deploy
  script:
    - mkdir .public
    - cp -r * .public
    - mv .public public
  artifacts:
    paths:
      - public
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
  environment: production
```

This example moves all files from the root of the project to the `public/` directory.
The `.public` workaround is so `cp` does not also copy `public/` to itself in an infinite loop.

**Additional details**:

You must:

- Place any static content in a `public/` directory.
- Define [`artifacts`](#artifacts) with a path to the `public/` directory.

### `parallel`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336576) in GitLab 15.9, the maximum value for `parallel` is increased from 50 to 200.

Use `parallel` to run a job multiple times in parallel in a single pipeline.

Multiple runners must exist, or a single runner must be configured to run multiple jobs concurrently.

Parallel jobs are named sequentially from `job_name 1/N` to `job_name N/N`.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A numeric value from `2` to `200`.

**Example of `parallel`**:

```yaml
test:
  script: rspec
  parallel: 5
```

This example creates 5 jobs that run in parallel, named `test 1/5` to `test 5/5`.

**Additional details**:

- Every parallel job has a `CI_NODE_INDEX` and `CI_NODE_TOTAL`
  [predefined CI/CD variable](../variables/index.md#predefined-cicd-variables) set.

**Related topics**:

- [Parallelize large jobs](../jobs/job_control.md#parallelize-large-jobs).

#### `parallel:matrix`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15356) in GitLab 13.3.
> - The job naming style was [improved in GitLab 13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/230452).
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/336576) in GitLab 15.9, the maximum number of permutations is increased from 50 to 200.

Use `parallel:matrix` to run a job multiple times in parallel in a single pipeline,
but with different variable values for each instance of the job.

Multiple runners must exist, or a single runner must be configured to run multiple jobs concurrently.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array of hashes of variables:

- The variable names can use only numbers, letters, and underscores (`_`).
- The values must be either a string, or an array of strings.
- The number of permutations cannot exceed 200.

**Example of `parallel:matrix`**:

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: aws
        STACK:
          - monitoring
          - app1
          - app2
      - PROVIDER: ovh
        STACK: [monitoring, backup, app]
      - PROVIDER: [gcp, vultr]
        STACK: [data, processing]
  environment: $PROVIDER/$STACK
```

The example generates 10 parallel `deploystacks` jobs, each with different values
for `PROVIDER` and `STACK`:

```plaintext
deploystacks: [aws, monitoring]
deploystacks: [aws, app1]
deploystacks: [aws, app2]
deploystacks: [ovh, monitoring]
deploystacks: [ovh, backup]
deploystacks: [ovh, app]
deploystacks: [gcp, data]
deploystacks: [gcp, processing]
deploystacks: [vultr, data]
deploystacks: [vultr, processing]
```

**Additional details**:

- `parallel:matrix` jobs add the variable values to the job names to differentiate
  the jobs from each other, but [large values can cause names to exceed limits](https://gitlab.com/gitlab-org/gitlab/-/issues/362262):
  - Job names must be [255 characters or fewer](../jobs/index.md#job-name-limitations).
  - When using [`needs`](#needs), job names must be 128 characters or fewer.

**Related topics**:

- [Run a one-dimensional matrix of parallel jobs](../jobs/job_control.md#run-a-one-dimensional-matrix-of-parallel-jobs).
- [Run a matrix of triggered parallel jobs](../jobs/job_control.md#run-a-matrix-of-parallel-trigger-jobs).
- [Select different runner tags for each parallel matrix job](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job).

### `release`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/19298) in GitLab 13.2.

Use `release` to create a [release](../../user/project/releases/index.md).

The release job must have access to the [`release-cli`](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs),
which must be in the `$PATH`.

If you use the [Docker executor](https://docs.gitlab.com/runner/executors/docker.html),
you can use this image from the GitLab Container Registry: `registry.gitlab.com/gitlab-org/release-cli:latest`

If you use the [Shell executor](https://docs.gitlab.com/runner/executors/shell.html) or similar,
[install `release-cli`](../../user/project/releases/release_cli.md) on the server where the runner is registered.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: The `release` subkeys:

- [`tag_name`](#releasetag_name)
- [`tag_message`](#releasetag_message) (optional)
- [`name`](#releasename) (optional)
- [`description`](#releasedescription)
- [`ref`](#releaseref) (optional)
- [`milestones`](#releasemilestones) (optional)
- [`released_at`](#releasereleased_at) (optional)
- [`assets:links`](#releaseassetslinks) (optional)

**Example of `release` keyword**:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Running the release job."
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the release-cli.'
```

This example creates a release:

- When you push a Git tag.
- When you add a Git tag in the UI at **Repository > Tags**.

**Additional details**:

- All release jobs, except [trigger](#trigger) jobs, must include the `script` keyword. A release
  job can use the output from script commands. If you don't need the script, you can use a placeholder:

  ```yaml
  script:
    - echo "release job"
  ```

  An [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/223856) exists to remove this requirement.

- The `release` section executes after the `script` keyword and before the `after_script`.
- A release is created only if the job's main script succeeds.
- If the release already exists, it is not updated and the job with the `release` keyword fails.

**Related topics**:

- [CI/CD example of the `release` keyword](../../user/project/releases/index.md#creating-a-release-by-using-a-cicd-job).
- [Create multiple releases in a single pipeline](../../user/project/releases/index.md#create-multiple-releases-in-a-single-pipeline).
- [Use a custom SSL CA certificate authority](../../user/project/releases/index.md#use-a-custom-ssl-ca-certificate-authority).

#### `release:tag_name`

Required. The Git tag for the release.

If the tag does not exist in the project yet, it is created at the same time as the release.
New tags use the SHA associated with the pipeline.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A tag name.

CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Example of `release:tag_name`**:

To create a release when a new tag is added to the project:

- Use the `$CI_COMMIT_TAG` CI/CD variable as the `tag_name`.
- Use [`rules:if`](#rulesif) or [`only: tags`](#onlyrefs--exceptrefs) to configure
  the job to run only for new tags.

```yaml
job:
  script: echo "Running the release job for the new tag."
  release:
    tag_name: $CI_COMMIT_TAG
    description: 'Release description'
  rules:
    - if: $CI_COMMIT_TAG
```

To create a release and a new tag at the same time, your [`rules`](#rules) or [`only`](#only--except)
should **not** configure the job to run only for new tags. A semantic versioning example:

```yaml
job:
  script: echo "Running the release job and creating a new tag."
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: 'Release description'
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

#### `release:tag_message`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363024) in GitLab 15.3. Supported by `release-cli` v0.12.0 or later.

If the tag does not exist, the newly created tag is annotated with the message specified by `tag_message`.
If omitted, a lightweight tag is created.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A text string.

**Example of `release:tag_message`**:

```yaml
  release_job:
    stage: release
    release:
      tag_name: $CI_COMMIT_TAG
      description: 'Release description'
      tag_message: 'Annotated tag message'
```

#### `release:name`

The release name. If omitted, it is populated with the value of `release: tag_name`.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A text string.

**Example of `release:name`**:

```yaml
  release_job:
    stage: release
    release:
      name: 'Release $CI_COMMIT_TAG'
```

#### `release:description`

The long description of the release.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A string with the long description.
- The path to a file that contains the description. Introduced in [GitLab 13.7](https://gitlab.com/gitlab-org/release-cli/-/merge_requests/67).
  - The file location must be relative to the project directory (`$CI_PROJECT_DIR`).
  - If the file is a symbolic link, it must be in the `$CI_PROJECT_DIR`.
  - The `./path/to/file` and filename can't contain spaces.

**Example of `release:description`**:

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: './path/to/CHANGELOG.md'
```

#### `release:ref`

The `ref` for the release, if the `release: tag_name` doesn't exist yet.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- A commit SHA, another tag name, or a branch name.

#### `release:milestones`

The title of each milestone the release is associated with.

#### `release:released_at`

The date and time when the release is ready.

**Possible inputs**:

- A date enclosed in quotes and expressed in ISO 8601 format.

**Example of `release:released_at`**:

```yaml
released_at: '2021-03-15T08:00:00Z'
```

**Additional details**:

- If it is not defined, the current date and time is used.

#### `release:assets:links`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271454) in GitLab 13.12.

Use `release:assets:links` to include [asset links](../../user/project/releases/release_fields.md#release-assets) in the release.

Requires `release-cli` version v0.4.0 or later.

**Example of `release:assets:links`**:

```yaml
assets:
  links:
    - name: 'asset1'
      url: 'https://example.com/assets/1'
    - name: 'asset2'
      url: 'https://example.com/assets/2'
      filepath: '/pretty/url/1' # optional
      link_type: 'other' # optional
```

### `resource_group`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15536) in GitLab 12.7.

Use `resource_group` to create a [resource group](../resource_groups/index.md) that
ensures a job is mutually exclusive across different pipelines for the same project.

For example, if multiple jobs that belong to the same resource group are queued simultaneously,
only one of the jobs starts. The other jobs wait until the `resource_group` is free.

Resource groups behave similar to semaphores in other programming languages.

You can define multiple resource groups per environment. For example,
when deploying to physical devices, you might have multiple physical devices. Each device
can be deployed to, but only one deployment can occur per device at any given time.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- Only letters, digits, `-`, `_`, `/`, `$`, `{`, `}`, `.`, and spaces.
  It can't start or end with `/`. CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Example of `resource_group`**:

```yaml
deploy-to-production:
  script: deploy
  resource_group: production
```

In this example, two `deploy-to-production` jobs in two separate pipelines can never run at the same time. As a result,
you can ensure that concurrent deployments never happen to the production environment.

**Related topics**:

- [Pipeline-level concurrency control with cross-project/parent-child pipelines](../resource_groups/index.md#pipeline-level-concurrency-control-with-cross-projectparent-child-pipelines).

### `retry`

Use `retry` to configure how many times a job is retried if it fails.
If not defined, defaults to `0` and jobs do not retry.

When a job fails, the job is processed up to two more times, until it succeeds or
reaches the maximum number of retries.

By default, all failure types cause the job to be retried. Use [`retry:when`](#retrywhen)
to select which failures to retry on.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- `0` (default), `1`, or `2`.

**Example of `retry`**:

```yaml
test:
  script: rspec
  retry: 2
```

#### `retry:when`

Use `retry:when` with `retry:max` to retry jobs for only specific failure cases.
`retry:max` is the maximum number of retries, like [`retry`](#retry), and can be
`0`, `1`, or `2`.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- A single failure type, or an array of one or more failure types:

<!--
  If you change any of the values below, make sure to update the `RETRY_WHEN_IN_DOCUMENTATION`
  array in `spec/lib/gitlab/ci/config/entry/retry_spec.rb`.
  The test there makes sure that all documented
  values are valid as a configuration option and therefore should always
  stay in sync with this documentation.
-->

- `always`: Retry on any failure (default).
- `unknown_failure`: Retry when the failure reason is unknown.
- `script_failure`: Retry when:
  - The script failed.
  - The runner failed to pull the Docker image. For `docker`, `docker+machine`, `kubernetes` [executors](https://docs.gitlab.com/runner/executors/).
- `api_failure`: Retry on API failure.
- `stuck_or_timeout_failure`: Retry when the job got stuck or timed out.
- `runner_system_failure`: Retry if there is a runner system failure (for example, job setup failed).
- `runner_unsupported`: Retry if the runner is unsupported.
- `stale_schedule`: Retry if a delayed job could not be executed.
- `job_execution_timeout`: Retry if the script exceeded the maximum execution time set for the job.
- `archived_failure`: Retry if the job is archived and can't be run.
- `unmet_prerequisites`: Retry if the job failed to complete prerequisite tasks.
- `scheduler_failure`: Retry if the scheduler failed to assign the job to a runner.
- `data_integrity_failure`: Retry if there is a structural integrity problem detected.

**Example of `retry:when`** (single failure type):

```yaml
test:
  script: rspec
  retry:
    max: 2
    when: runner_system_failure
```

If there is a failure other than a runner system failure, the job is not retried.

**Example of `retry:when`** (array of failure types):

```yaml
test:
  script: rspec
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

**Related topics**:

You can specify the number of [retry attempts for certain stages of job execution](../runners/configure_runners.md#job-stages-attempts)
using variables.

### `rules`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27863) in GitLab 12.3.

Use `rules` to include or exclude jobs in pipelines.

Rules are evaluated when the pipeline is created, and evaluated *in order*
until the first match. When a match is found, the job is either included or excluded from the pipeline,
depending on the configuration.

You cannot use dotenv variables created in job scripts in rules, because rules are evaluated before any jobs run.

`rules` replaces [`only/except`](#only--except) and they can't be used together
in the same job. If you configure one job to use both keywords, the GitLab returns
a `key may not be used with rules` error.

`rules` accepts an array of rules defined with:

- `if`
- `changes`
- `exists`
- `allow_failure`
- `variables`
- `when`

You can combine multiple keywords together for [complex rules](../jobs/job_control.md#complex-rules).

The job is added to the pipeline:

- If an `if`, `changes`, or `exists` rule matches and also has `when: on_success` (default),
  `when: delayed`, or `when: always`.
- If a rule is reached that is only `when: on_success`, `when: delayed`, or `when: always`.

The job is not added to the pipeline:

- If no rules match.
- If a rule matches and has `when: never`.

You can use [`!reference` tags](yaml_optimization.md#reference-tags) to [reuse `rules` configuration](../jobs/job_control.md#reuse-rules-in-different-jobs)
in different jobs.

#### `rules:if`

Use `rules:if` clauses to specify when to add a job to a pipeline:

- If an `if` statement is true, add the job to the pipeline.
- If an `if` statement is true, but it's combined with `when: never`, do not add the job to the pipeline.
- If no `if` statements are true, do not add the job to the pipeline.

`if` clauses are evaluated based on the values of [CI/CD variables](../variables/index.md)
or [predefined CI/CD variables](../variables/predefined_variables.md), with
[some exceptions](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Keyword type**: Job-specific and pipeline-specific. You can use it as part of a job
to configure the job behavior, or with [`workflow`](#workflow) to configure the pipeline behavior.

**Possible inputs**:

- A [CI/CD variable expression](../jobs/job_control.md#cicd-variable-expressions).

**Example of `rules:if`**:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/ && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME != $CI_DEFAULT_BRANCH
      when: never
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/
      when: manual
      allow_failure: true
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME
```

**Additional details**:

- If a rule matches and has no `when` defined, the rule uses the `when`
  defined for the job, which defaults to `on_success` if not defined.
- In GitLab 14.5 and earlier, you can define `when` once per rule, or once at the job-level,
  which applies to all rules. You can't mix `when` at the job-level with `when` in rules.
- In GitLab 14.6 and later, you can [mix `when` at the job-level with `when` in rules](https://gitlab.com/gitlab-org/gitlab/-/issues/219437).
  `when` configuration in `rules` takes precedence over `when` at the job-level.
- Unlike variables in [`script`](../variables/index.md#use-cicd-variables-in-job-scripts)
  sections, variables in rules expressions are always formatted as `$VARIABLE`.
  - You can use `rules:if` with `include` to [conditionally include other configuration files](includes.md#use-rules-with-include).
- CI/CD variables on the right side of `=~` and `!~` expressions are [evaluated as regular expressions](../jobs/job_control.md#store-the-regex-pattern-in-a-variable).

**Related topics**:

- [Common `if` expressions for `rules`](../jobs/job_control.md#common-if-clauses-for-rules).
- [Avoid duplicate pipelines](../jobs/job_control.md#avoid-duplicate-pipelines).
- [Use `rules` to run merge request pipelines](../pipelines/merge_request_pipelines.md#use-rules-to-add-jobs).

#### `rules:changes`

Use `rules:changes` to specify when to add a job to a pipeline by checking for changes
to specific files.

WARNING:
You should use `rules: changes` only with **branch pipelines** or **merge request pipelines**.
You can use `rules: changes` with other pipeline types, but `rules: changes` always
evaluates to true when there is no Git `push` event. Tag pipelines, scheduled pipelines, manual pipelines,
and so on do **not** have a Git `push` event associated with them. A `rules: changes` job
is **always** added to those pipelines if there is no `if` that limits the job to
branch or merge request pipelines.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

An array including any number of:

- Paths to files. In GitLab 13.6 and later, [file paths can include variables](../jobs/job_control.md#variables-in-ruleschanges).
  A file path array can also be in [`rules:changes:paths`](#ruleschangespaths).
- Wildcard paths for:
  - Single directories, for example `path/to/directory/*`.
  - A directory and all its subdirectories, for example `path/to/directory/**/*`.
- Wildcard [glob](https://en.wikipedia.org/wiki/Glob_(programming)) paths for all files
  with the same extension or multiple extensions, for example `*.md` or `path/to/directory/*.{rb,py,sh}`.
  See the [Ruby `fnmatch` documentation](https://docs.ruby-lang.org/en/master/File.html#method-c-fnmatch)
  for the supported syntax list.
- Wildcard paths to files in the root directory, or all directories, wrapped in double quotes.
  For example `"*.json"` or `"**/*.json"`.

**Example of `rules:changes`**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile
      when: manual
      allow_failure: true
```

- If the pipeline is a merge request pipeline, check `Dockerfile` for changes.
- If `Dockerfile` has changed, add the job to the pipeline as a manual job, and the pipeline
  continues running even if the job is not triggered (`allow_failure: true`).
- A maximum of 50 patterns or file paths can be defined per `rules:changes` section.
- If `Dockerfile` has not changed, do not add job to any pipeline (same as `when: never`).
- [`rules:changes:paths`](#ruleschangespaths) is the same as `rules:changes` without
  any subkeys.

**Additional details**:

- `rules: changes` works the same way as [`only: changes` and `except: changes`](#onlychanges--exceptchanges).
- You can use `when: never` to implement a rule similar to [`except:changes`](#onlychanges--exceptchanges).
- `changes` resolves to `true` if any of the matching files are changed (an `OR` operation).

**Related topics**:

- [Jobs or pipelines can run unexpectedly when using `rules: changes`](../jobs/job_control.md#jobs-or-pipelines-run-unexpectedly-when-using-changes).

##### `rules:changes:paths`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90171) in GitLab 15.2.

Use `rules:changes` to specify that a job only be added to a pipeline when specific
files are changed, and use `rules:changes:paths` to specify the files.

`rules:changes:paths` is the same as using [`rules:changes`](#ruleschanges) without
any subkeys. All additional details and related topics are the same.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- An array of file paths. [File paths can include variables](../jobs/job_control.md#variables-in-ruleschanges).

**Example of `rules:changes:paths`**:

```yaml
docker-build-1:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        - Dockerfile

docker-build-2:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
```

In this example, both jobs have the same behavior.

##### `rules:changes:compare_to`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/293645) in GitLab 15.3 [with a flag](../../administration/feature_flags.md) named `ci_rules_changes_compare`. Enabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/366412) in GitLab 15.5. Feature flag `ci_rules_changes_compare` removed.

Use `rules:changes:compare_to` to specify which ref to compare against for changes to the files
listed under [`rules:changes:paths`](#ruleschangespaths).

**Keyword type**: Job keyword. You can use it only as part of a job, and it must be combined with `rules:changes:paths`.

**Possible inputs**:

- A branch name, like `main`, `branch1`, or `refs/heads/branch1`.
- A tag name, like `tag1` or `refs/tags/tag1`.
- A commit SHA, like `2fg31ga14b`.

**Example of `rules:changes:compare_to`**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      changes:
        paths:
          - Dockerfile
        compare_to: 'refs/heads/branch1'
```

In this example, the `docker build` job is only included when the `Dockerfile` has changed
relative to `refs/heads/branch1` and the pipeline source is a merge request event.

#### `rules:exists`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24021) in GitLab 12.4.
> - CI/CD variable support [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/283881) in GitLab 15.6.

Use `exists` to run a job when certain files exist in the repository.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- An array of file paths. Paths are relative to the project directory (`$CI_PROJECT_DIR`) and can't directly link outside it. File paths can use glob patterns and [CI/CD variables](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Example of `rules:exists`**:

```yaml
job:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - Dockerfile
```

`job` runs if a `Dockerfile` exists anywhere in the repository.

**Additional details**:

- Glob patterns are interpreted with Ruby [`File.fnmatch`](https://docs.ruby-lang.org/en/2.7.0/File.html#method-c-fnmatch)
  with the flags `File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB`.
- For performance reasons, GitLab performs a maximum of 10,000 checks against
  `exists` patterns or file paths. After the 10,000th check, rules with patterned
  globs always match. In other words, the `exists` rule always assumes a match in
  projects with more than 10,000 files, or if there are fewer than 10,000 files but
  the `exists` rules are checked more than 10,000 times.
- A maximum of 50 patterns or file paths can be defined per `rules:exists` section.
- `exists` resolves to `true` if any of the listed files are found (an `OR` operation).

#### `rules:allow_failure`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30235) in GitLab 12.8.

Use [`allow_failure: true`](#allow_failure) in `rules` to allow a job to fail
without stopping the pipeline.

You can also use `allow_failure: true` with a manual job. The pipeline continues
running without waiting for the result of the manual job. `allow_failure: false`
combined with `when: manual` in rules causes the pipeline to wait for the manual
job to run before continuing.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `true` or `false`. Defaults to `false` if not defined.

**Example of `rules:allow_failure`**:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH
      when: manual
      allow_failure: true
```

If the rule matches, then the job is a manual job with `allow_failure: true`.

**Additional details**:

- The rule-level `rules:allow_failure` overrides the job-level [`allow_failure`](#allow_failure),
  and only applies when the specific rule triggers the job.

#### `rules:variables`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/209864) in GitLab 13.7.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/289803) in GitLab 13.10.

Use [`variables`](#variables) in `rules` to define variables for specific conditions.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**:

- A hash of variables in the format `VARIABLE-NAME: value`.

**Example of `rules:variables`**:

```yaml
job:
  variables:
    DEPLOY_VARIABLE: "default-deploy"
  rules:
    - if: $CI_COMMIT_REF_NAME == $CI_DEFAULT_BRANCH
      variables:                              # Override DEPLOY_VARIABLE defined
        DEPLOY_VARIABLE: "deploy-production"  # at the job level.
    - if: $CI_COMMIT_REF_NAME =~ /feature/
      variables:
        IS_A_FEATURE: "true"                  # Define a new variable.
  script:
    - echo "Run script with $DEPLOY_VARIABLE as an argument"
    - echo "Run another script if $IS_A_FEATURE exists"
```

### `script`

Use `script` to specify commands for the runner to execute.

All jobs except [trigger jobs](#trigger) require a `script` keyword.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array including:

- Single line commands.
- Long commands [split over multiple lines](script.md#split-long-commands).
- [YAML anchors](yaml_optimization.md#yaml-anchors-for-scripts).

CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Example of `script`**:

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - uname -a
    - bundle exec rspec
```

**Additional details**:

- When you use [these special characters in `script`](script.md#use-special-characters-with-script), you must use single quotes (`'`) or double quotes (`"`) .

**Related topics**:

- You can [ignore non-zero exit codes](script.md#ignore-non-zero-exit-codes).
- [Use color codes with `script`](script.md#add-color-codes-to-script-output)
  to make job logs easier to review.
- [Create custom collapsible sections](../jobs/index.md#custom-collapsible-sections)
  to simplify job log output.

### `secrets` **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33014) in GitLab 13.4.

Use `secrets` to specify [CI/CD secrets](../secrets/index.md) to:

- Retrieve from an external secrets provider.
- Make available in the job as [CI/CD variables](../variables/index.md)
  ([`file` type](../variables/index.md#use-file-type-cicd-variables) by default).

This keyword must be used with `secrets:vault`.

#### `secrets:vault`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/28321) in GitLab 13.4 and GitLab Runner 13.4.

Use `secrets:vault` to specify secrets provided by a [HashiCorp Vault](https://www.vaultproject.io/).

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `engine:name`: Name of the secrets engine.
- `engine:path`: Path to the secrets engine.
- `path`: Path to the secret.
- `field`: Name of the field where the password is stored.

**Example of `secrets:vault`**:

To specify all details explicitly and use the [KV-V2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) secrets engine:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault:  # Translates to secret: `ops/data/production/db`, field: `password`
        engine:
          name: kv-v2
          path: ops
        path: production/db
        field: password
```

You can shorten this syntax. With the short syntax, `engine:name` and `engine:path`
both default to `kv-v2`:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password  # Translates to secret: `kv-v2/data/production/db`, field: `password`
```

To specify a custom secrets engine path in the short syntax, add a suffix that starts with `@`:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:  # Store the path to the secret in this CI/CD variable
      vault: production/db/password@ops  # Translates to secret: `ops/data/production/db`, field: `password`
```

#### `secrets:file`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/250695) in GitLab 14.1 and GitLab Runner 14.1.

Use `secrets:file` to configure the secret to be stored as either a
[`file` or `variable` type CI/CD variable](../variables/index.md#use-file-type-cicd-variables)

By default, the secret is passed to the job as a `file` type CI/CD variable. The value
of the secret is stored in the file and the variable contains the path to the file.

If your software can't use `file` type CI/CD variables, set `file: false` to store
the secret value directly in the variable.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- `true` (default) or `false`.

**Example of `secrets:file`**:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      file: false
```

**Additional details**:

- The `file` keyword is a setting for the CI/CD variable and must be nested under
  the CI/CD variable name, not in the `vault` section.

#### `secrets:token`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356986) in GitLab 15.8.

Use `secrets:token` to explicitly select a token to use when authenticating with Vault by referencing the token's CI/CD variable.

This keyword has no effect if [**Limit JSON Web Token (JWT) access**](../secrets/id_token_authentication.md#enable-automatic-id-token-authentication)
is disabled.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- The name of an ID token

**Example of `secrets:token`**:

```yaml
job:
  id_tokens:
    AWS_TOKEN:
      aud: https://aws.example.com
    VAULT_TOKEN:
      aud: https://vault.example.com
  secrets:
    DB_PASSWORD:
      vault: gitlab/production/db
      token: $VAULT_TOKEN
```

**Additional details**:

- When the `token` keyword is not set and **Limit JSON Web Token (JWT) access** enabled, the first ID token
  is used to authenticate.
- When **Limit JSON Web Token (JWT) access** is disabled, the `token` keyword is ignored and the `CI_JOB_JWT`
  CI/CD variable is used to authenticate.

### `services`

Use `services` to specify any additional Docker images that your scripts require to run successfully. The [`services` image](../services/index.md) is linked
to the image specified in the [`image`](#image) keyword.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**: The name of the services image, including the registry path if needed, in one of these formats:

- `<image-name>` (Same as using `<image-name>` with the `latest` tag)
- `<image-name>:<tag>`
- `<image-name>@<digest>`

CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file), but [not for `alias`](https://gitlab.com/gitlab-org/gitlab/-/issues/19561).

**Example of `services`**:

```yaml
default:
  image:
    name: ruby:2.6
    entrypoint: ["/bin/bash"]

  services:
    - name: my-postgres:11.7
      alias: db-postgres
      entrypoint: ["/usr/local/bin/db-postgres"]
      command: ["start"]

  before_script:
    - bundle install

test:
  script:
    - bundle exec rake spec
```

In this example, GitLab launches two containers for the job:

- A Ruby container that runs the `script` commands.
- A PostgreSQL container. The `script` commands in the Ruby container can connect to
  the PostgreSQL database at the `db-postgrest` hostname.

**Related topics**:

- [Available settings for `services`](../services/index.md#available-settings-for-services).
- [Define `services` in the `.gitlab-ci.yml` file](../services/index.md#define-services-in-the-gitlab-ciyml-file).
- [Run your CI/CD jobs in Docker containers](../docker/using_docker_images.md).
- [Use Docker to build Docker images](../docker/using_docker_build.md).

#### `service:pull_policy`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/21619) in GitLab 15.1 [with a flag](../../administration/feature_flags.md) named `ci_docker_image_pull_policy`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) in GitLab 15.2.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) in GitLab 15.4. [Feature flag `ci_docker_image_pull_policy`](https://gitlab.com/gitlab-org/gitlab/-/issues/363186) removed.
> - Requires GitLab Runner 15.1 or later.

The pull policy that the runner uses to fetch the Docker image.

**Keyword type**: Job keyword. You can use it only as part of a job or in the [`default` section](#default).

**Possible inputs**:

- A single pull policy, or multiple pull policies in an array.
  Can be `always`, `if-not-present`, or `never`.

**Examples of `service:pull_policy`**:

```yaml
job1:
  script: echo "A single pull policy."
  services:
    - name: postgres:11.6
      pull_policy: if-not-present

job2:
  script: echo "Multiple pull policies."
  services:
    - name: postgres:11.6
      pull_policy: [always, if-not-present]
```

**Additional details**:

- If the runner does not support the defined pull policy, the job fails with an error similar to:
  `ERROR: Job failed (system failure): the configured PullPolicies ([always]) are not allowed by AllowedPullPolicies ([never])`.

**Related topics**:

- [Run your CI/CD jobs in Docker containers](../docker/using_docker_images.md).
- [How runner pull policies work](https://docs.gitlab.com/runner/executors/docker.html#how-pull-policies-work).
- [Using multiple pull policies](https://docs.gitlab.com/runner/executors/docker.html#using-multiple-pull-policies).

### `stage`

Use `stage` to define which [stage](#stages) a job runs in. Jobs in the same
`stage` can execute in parallel (see **Additional details**).

If `stage` is not defined, the job uses the `test` stage by default.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: A string, which can be a:

- [Default stage](#stages).
- User-defined stages.

**Example of `stage`**:

```yaml
stages:
  - build
  - test
  - deploy

job1:
  stage: build
  script:
    - echo "This job compiles code."

job2:
  stage: test
  script:
    - echo "This job tests the compiled code. It runs when the build stage completes."

job3:
  script:
    - echo "This job also runs in the test stage".

job4:
  stage: deploy
  script:
    - echo "This job deploys the code. It runs when the test stage completes."
  environment: production
```

**Additional details**:

- Jobs can run in parallel if they run on different runners.
- If you have only one runner, jobs can run in parallel if the runner's
  [`concurrent` setting](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)
  is greater than `1`.

#### `stage: .pre`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31441) in GitLab 12.4.

Use the `.pre` stage to make a job run at the start of a pipeline. `.pre` is
always the first stage in a pipeline. User-defined stages execute after `.pre`.
You do not have to define `.pre` in [`stages`](#stages).

If a pipeline contains only jobs in the `.pre` or `.post` stages, it does not run.
There must be at least one other job in a different stage.

**Keyword type**: You can only use it with a job's `stage` keyword.

**Example of `stage: .pre`**:

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

first-job:
  stage: .pre
  script:
    - echo "This job runs in the .pre stage, before all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

#### `stage: .post`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31441) in GitLab 12.4.

Use the `.post` stage to make a job run at the end of a pipeline. `.post`
is always the last stage in a pipeline. User-defined stages execute before `.post`.
You do not have to define `.post` in [`stages`](#stages).

If a pipeline contains only jobs in the `.pre` or `.post` stages, it does not run.
There must be at least one other job in a different stage.

**Keyword type**: You can only use it with a job's `stage` keyword.

**Example of `stage: .post`**:

```yaml
stages:
  - build
  - test

job1:
  stage: build
  script:
    - echo "This job runs in the build stage."

last-job:
  stage: .post
  script:
    - echo "This job runs in the .post stage, after all other stages."

job2:
  stage: test
  script:
    - echo "This job runs in the test stage."
```

**Additional details:**

- If a pipeline has jobs with [`needs: []`](#needs) and jobs in the `.pre` stage, they will
  all start as soon as the pipeline is created. Jobs with `needs: []` start immediately,
  ignoring any stage configuration.

### `tags`

> - A limit of 50 tags per job [enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/338929) in GitLab 14.3.
> - A limit of 50 tags per job [enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/339855) in GitLab 14.3.

Use `tags` to select a specific runner from the list of all runners that are
available for the project.

When you register a runner, you can specify the runner's tags, for
example `ruby`, `postgres`, or `development`. To pick up and run a job, a runner must
be assigned every tag listed in the job.

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**:

- An array of tag names.
- CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
  in GitLab 14.1 and later.

**Example of `tags`**:

```yaml
job:
  tags:
    - ruby
    - postgres
```

In this example, only runners with *both* the `ruby` and `postgres` tags can run the job.

**Additional details**:

- In [GitLab 14.3](https://gitlab.com/gitlab-org/gitlab/-/issues/338479) and later,
  the number of tags must be less than `50`.

**Related topics**:

- [Use tags to control which jobs a runner can run](../runners/configure_runners.md#use-tags-to-control-which-jobs-a-runner-can-run).
- [Select different runner tags for each parallel matrix job](../jobs/job_control.md#select-different-runner-tags-for-each-parallel-matrix-job).

### `timeout`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14887) in GitLab 12.3.

Use `timeout` to configure a timeout for a specific job. If the job runs for longer
than the timeout, the job fails.

The job-level timeout can be longer than the [project-level timeout](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run).
but can't be longer than the [runner's timeout](../runners/configure_runners.md#set-maximum-job-timeout-for-a-runner).

**Keyword type**: Job keyword. You can use it only as part of a job or in the
[`default` section](#default).

**Possible inputs**: A period of time written in natural language. For example, these are all equivalent:

- `3600 seconds`
- `60 minutes`
- `one hour`

**Example of `timeout`**:

```yaml
build:
  script: build.sh
  timeout: 3 hours 30 minutes

test:
  script: rspec
  timeout: 3h 30m
```

### `trigger`

Use `trigger` to declare that a job is a "trigger job" which starts a
[downstream pipeline](../pipelines/downstream_pipelines.md) that is either:

- [A multi-project pipeline](../pipelines/downstream_pipelines.md#multi-project-pipelines).
- [A child pipeline](../pipelines/downstream_pipelines.md#parent-child-pipelines).

Trigger jobs can use only a limited set of GitLab CI/CD configuration keywords.
The keywords available for use in trigger jobs are:

- [`allow_failure`](#allow_failure).
- [`extends`](#extends).
- [`needs`](#needs), but not [`needs:project`](#needsproject).
- [`only` and `except`](#only--except).
- [`rules`](#rules).
- [`stage`](#stage).
- [`trigger`](#trigger).
- [`variables`](#variables).
- [`when`](#when) (only with a value of `on_success`, `on_failure`, or `always`).

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- For multi-project pipelines, the path to the downstream project. CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
  in GitLab 15.3 and later, but not [job-level persisted variables](../variables/where_variables_can_be_used.md#persisted-variables).
  Alternatively, use [`trigger:project](#triggerproject).
- For child pipelines, use [`trigger:include`](#triggerinclude).

**Example of `trigger`**:

```yaml
trigger-multi-project-pipeline:
  trigger: my-group/my-project
```

**Additional details**:

- You [cannot use the API to start `when:manual` trigger jobs](https://gitlab.com/gitlab-org/gitlab/-/issues/284086).
- In [GitLab 13.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/201938), you
  can use [`when:manual`](#when) in the same job as `trigger`. In GitLab 13.4 and
  earlier, using them together causes the error `jobs:#{job-name} when should be on_success, on_failure or always`.
- You cannot [manually specify CI/CD variables](../jobs/index.md#specifying-variables-when-running-manual-jobs)
  before running a manual trigger job.
- [Manual pipeline variables](../variables/index.md#override-a-defined-cicd-variable)
  and [scheduled pipeline variables](../pipelines/schedules.md#add-a-pipeline-schedule)
  are not passed to downstream pipelines by default. Use [trigger:forward](#triggerforward)
  to forward these variables to downstream pipelines.
- [Job-level persisted variables](../variables/where_variables_can_be_used.md#persisted-variables)
  are not available in trigger jobs.

**Related topics**:

- [Multi-project pipeline configuration examples](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
- To run a pipeline for a specific branch, tag, or commit, you can use a [trigger token](../triggers/index.md)
  to authenticate with the [pipeline triggers API](../../api/pipeline_triggers.md).
  The trigger token is different than the `trigger` keyword.

#### `trigger:include`

Use `trigger:include` to declare that a job is a "trigger job" which starts a
[child pipeline](../pipelines/downstream_pipelines.md#parent-child-pipelines).

Use `trigger:include:artifact` to trigger a [dynamic child pipeline](../pipelines/downstream_pipelines.md#dynamic-child-pipelines).

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- The path to the child pipeline's configuration file.

**Example of `trigger:include`**:

```yaml
trigger-child-pipeline:
  trigger:
    include: path/to/child-pipeline.gitlab-ci.yml
```

**Related topics**:

- [Child pipeline configuration examples](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).

#### `trigger:project`

Use `trigger:project` to declare that a job is a "trigger job" which starts a
[multi-project pipeline](../pipelines/downstream_pipelines.md#multi-project-pipelines).

By default, the multi-project pipeline triggers for the default branch. Use `trigger:branch`
to specify a different branch.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**:

- The path to the downstream project. CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
  in GitLab 15.3 and later, but not [job-level persisted variables](../variables/where_variables_can_be_used.md#persisted-variables).

**Example of `trigger:project`**:

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
```

**Example of `trigger:project` for a different branch**:

```yaml
trigger-multi-project-pipeline:
  trigger:
    project: my-group/my-project
    branch: development
```

**Related topics**:

- [Multi-project pipeline configuration examples](../pipelines/downstream_pipelines.md#trigger-a-downstream-pipeline-from-a-job-in-the-gitlab-ciyml-file).
- To run a pipeline for a specific branch, tag, or commit, you can also use a [trigger token](../triggers/index.md)
  to authenticate with the [pipeline triggers API](../../api/pipeline_triggers.md).
  The trigger token is different than the `trigger` keyword.

#### `trigger:strategy`

Use `trigger:strategy` to force the `trigger` job to wait for the downstream pipeline to complete
before it is marked as **success**.

This behavior is different than the default, which is for the `trigger` job to be marked as
**success** as soon as the downstream pipeline is created.

This setting makes your pipeline execution linear rather than parallel.

**Example of `trigger:strategy`**:

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
    strategy: depend
```

In this example, jobs from subsequent stages wait for the triggered pipeline to
successfully complete before starting.

**Additional details**:

- [Optional manual jobs](../jobs/job_control.md#types-of-manual-jobs) in the downstream pipeline
  do not affect the status of the downstream pipeline or the upstream trigger job.
  The downstream pipeline can complete successfully without running any optional manual jobs.
- [Blocking manual jobs](../jobs/job_control.md#types-of-manual-jobs) in the downstream pipeline
  must run before the trigger job is marked as successful or failed. The trigger job
  shows **pending** (**{status_pending}**) if the downstream pipeline status is
  **waiting for manual action** (**{status_manual}**) due to manual jobs. By default,
  jobs in later stages do not start until the trigger job completes.
- If the downstream pipeline has a failed job, but the job uses [`allow_failure: true`](#allow_failure),
  the downstream pipeline is considered successful and the trigger job shows **success**.

#### `trigger:forward`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213729) in GitLab 14.9 [with a flag](../../administration/feature_flags.md) named `ci_trigger_forward_variables`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/355572) in GitLab 14.10.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/355572) in GitLab 15.1. [Feature flag `ci_trigger_forward_variables`](https://gitlab.com/gitlab-org/gitlab/-/issues/355572) removed.

Use `trigger:forward` to specify what to forward to the downstream pipeline. You can control
what is forwarded to both [parent-child pipelines](../pipelines/downstream_pipelines.md#parent-child-pipelines)
and [multi-project pipelines](../pipelines/downstream_pipelines.md#multi-project-pipelines).

**Possible inputs**:

- `yaml_variables`: `true` (default), or `false`. When `true`, variables defined
  in the trigger job are passed to downstream pipelines.
- `pipeline_variables`: `true` or `false` (default). When `true`, [manual pipeline variables](../variables/index.md#override-a-defined-cicd-variable) and [scheduled pipeline variables](../pipelines/schedules.md#add-a-pipeline-schedule)
  are passed to downstream pipelines.

**Example of `trigger:forward`**:

[Run this pipeline manually](../pipelines/index.md#run-a-pipeline-manually), with
the CI/CD variable `MYVAR = my value`:

```yaml
variables: # default variables for each job
  VAR: value

# Default behavior:
# - VAR is passed to the child
# - MYVAR is not passed to the child
child1:
  trigger:
    include: .child-pipeline.yml

# Forward pipeline variables:
# - VAR is passed to the child
# - MYVAR is passed to the child
child2:
  trigger:
    include: .child-pipeline.yml
    forward:
      pipeline_variables: true

# Do not forward YAML variables:
# - VAR is not passed to the child
# - MYVAR is not passed to the child
child3:
  trigger:
    include: .child-pipeline.yml
    forward:
      yaml_variables: false
```

### `variables`

Use `variables` to define [CI/CD variables](../variables/index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file) for jobs.

**Keyword type**: Global and job keyword. You can use it at the global level,
and also at the job level.

If you define `variables` as a [global keyword](#keywords), it behaves like default variables
for all jobs. Each variable is copied to every job configuration when the pipeline is created.
If the job already has that variable defined, the [job-level variable takes precedence](../variables/index.md#cicd-variable-precedence).

Variables defined at the global-level cannot be used as inputs for other global keywords
like [`include`](includes.md#use-variables-with-include). These variables can only
be used at the job-level, in `script`, `before_script`, and `after_script` sections,
as well as inputs in some job keywords like [`rules`](../jobs/job_control.md#cicd-variable-expressions).

**Possible inputs**: Variable name and value pairs:

- The name can use only numbers, letters, and underscores (`_`). In some shells,
  the first character must be a letter.
- The value must be a string.

CI/CD variables [are supported](../variables/where_variables_can_be_used.md#gitlab-ciyml-file).

**Examples of `variables`**:

```yaml
variables:
  DEPLOY_SITE: "https://example.com/"

deploy_job:
  stage: deploy
  script:
    - deploy-script --url $DEPLOY_SITE --path "/"
  environment: production

deploy_review_job:
  stage: deploy
  variables:
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
  environment: production
```

**Additional details**:

- All YAML-defined variables are also set to any linked [Docker service containers](../services/index.md).
- YAML-defined variables are meant for non-sensitive project configuration. Store sensitive information
  in [protected variables](../variables/index.md#protect-a-cicd-variable) or [CI/CD secrets](../secrets/index.md).
- [Manual pipeline variables](../variables/index.md#override-a-defined-cicd-variable)
  and [scheduled pipeline variables](../pipelines/schedules.md#add-a-pipeline-schedule)
  are not passed to downstream pipelines by default. Use [trigger:forward](#triggerforward)
  to forward these variables to downstream pipelines.

**Related topics**:

- [Predefined variables](../variables/predefined_variables.md) are variables the runner
  automatically creates and makes available in the job.
- You can [configure runner behavior with variables](../runners/configure_runners.md#configure-runner-behavior-with-variables).

#### `variables:description`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30101) in GitLab 13.7.

Use the `description` keyword to define a description for a pipeline-level (global) variable.
The description displays with [the prefilled variable name when running a pipeline manually](../pipelines/index.md#prefill-variables-in-manual-pipelines).

**Keyword type**: Global keyword. You cannot use it for job-level variables.

**Possible inputs**:

- A string.

**Example of `variables:description`**:

```yaml
variables:
  DEPLOY_NOTE:
    description: "The deployment note. Explain the reason for this deployment."
```

**Additional details**:

- When used without `value`, the variable exists in pipelines that were not triggered manually,
  and the default value is an empty string (`''`).

#### `variables:value`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30101) in GitLab 13.7.

Use the `value` keyword to define a pipeline-level (global) variable's value. When used with
[`variables: description`](#variablesdescription), the variable value is [prefilled when running a pipeline manually](../pipelines/index.md#prefill-variables-in-manual-pipelines).

**Keyword type**: Global keyword. You cannot use it for job-level variables.

**Possible inputs**:

- A string.

**Example of `variables:value`**:

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    description: "The deployment target. Change this variable to 'canary' or 'production' if needed."
```

**Additional details**:

- If used without [`variables: description`](#variablesdescription), the behavior is
  the same as [`variables`](#variables).

#### `variables:options`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105502) in GitLab 15.7.

Use `variables:options` to define an array of values that are [selectable in the UI when running a pipeline manually](../pipelines/index.md#configure-a-list-of-selectable-prefilled-variable-values).

Must be used with `variables: value`, and the string defined for `value`:

- Must also be one of the strings in the `options` array.
- Is the default selection.

If there is no [`description`](#variablesdescription),
this keyword has no effect.

**Keyword type**: Global keyword. You cannot use it for job-level variables.

**Possible inputs**:

- An array of strings.

**Example of `variables:options`**:

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"
    options:
      - "production"
      - "staging"
      - "canary"
    description: "The deployment target. Set to 'staging' by default."
```

#### `variables:expand`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/353991) in GitLab 15.6 [with a flag](../../administration/feature_flags.md) named `ci_raw_variables_in_yaml_config`. Disabled by default.
> - [Enabled on GitLab.com](https://gitlab.com/gitlab-org/gitlab/-/issues/375034) in GitLab 15.6.
> - [Enabled on self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/375034) in GitLab 15.7.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/375034) in GitLab 15.8. Feature flag `ci_raw_variables_in_yaml_config` removed.

Use the `expand` keyword to configure a variable to be expandable or not.

**Keyword type**: Global and job keyword. You can use it at the global level, and also at the job level.

**Possible inputs**:

- `true` (default): The variable is expandable.
- `false`: The variable is not expandable.

**Example of `variables:expand`**:

```yaml
variables:
  VAR1: value1
  VAR2: value2 $VAR1
  VAR3:
    value: value3 $VAR1
    expand: false
```

- The result of `VAR2` is `value2 value1`.
- The result of `VAR3` is `value3 $VAR1`.

**Additional details**:

- The `expand` keyword can only be used with the global and job-level `variables` keywords.
  You can't use it with [`rules:variables`](#rulesvariables) or [`workflow:rules:variables`](#workflowrulesvariables).

### `when`

Use `when` to configure the conditions for when jobs run. If not defined in a job,
the default value is `when: on_success`.

**Keyword type**: Job keyword. You can use it as part of a job. `when: always` and `when: never` can also be used in [`workflow:rules`](#workflow).

**Possible inputs**:

- `on_success` (default): Run the job only when no jobs in earlier stages fail
  or have `allow_failure: true`.
- `on_failure`: Run the job only when at least one job in an earlier stage fails. A job in an earlier stage
  with `allow_failure: true` is always considered successful.
- `never`: Don't run the job regardless of the status of jobs in earlier stages.
  Can only be used in a [`rules`](#rules) section or `workflow: rules`.
- `always`: Run the job regardless of the status of jobs in earlier stages. Can also be used in `workflow:rules`.
- `manual`: Run the job only when [triggered manually](../jobs/job_control.md#create-a-job-that-must-be-run-manually).
- `delayed`: [Delay the execution of a job](../jobs/job_control.md#run-a-job-after-a-delay)
  for a specified duration.

**Example of `when`**:

```yaml
stages:
  - build
  - cleanup_build
  - test
  - deploy
  - cleanup

build_job:
  stage: build
  script:
    - make build

cleanup_build_job:
  stage: cleanup_build
  script:
    - cleanup build when failed
  when: on_failure

test_job:
  stage: test
  script:
    - make test

deploy_job:
  stage: deploy
  script:
    - make deploy
  when: manual
  environment: production

cleanup_job:
  stage: cleanup
  script:
    - cleanup after jobs
  when: always
```

In this example, the script:

1. Executes `cleanup_build_job` only when `build_job` fails.
1. Always executes `cleanup_job` as the last step in pipeline regardless of
   success or failure.
1. Executes `deploy_job` when you run it manually in the GitLab UI.

**Additional details**:

- In [GitLab 13.5 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/201938), you
  can use `when:manual` in the same job as [`trigger`](#trigger). In GitLab 13.4 and
  earlier, using them together causes the error `jobs:#{job-name} when should be on_success, on_failure or always`.
- The default behavior of `allow_failure` changes to `true` with `when: manual`.
  However, if you use `when: manual` with [`rules`](#rules), `allow_failure` defaults
  to `false`.

**Related topics**:

- `when` can be used with [`rules`](#rules) for more dynamic job control.
- `when` can be used with [`workflow`](#workflow) to control when a pipeline can start.

## Deprecated keywords

The following keywords are deprecated.

### Globally-defined `image`, `services`, `cache`, `before_script`, `after_script`

Defining `image`, `services`, `cache`, `before_script`, and
`after_script` globally is deprecated. Support could be removed
from a future release.

Use [`default`](#default) instead. For example:

```yaml
default:
  image: ruby:3.0
  services:
    - docker:dind
  cache:
    paths: [vendor/]
  before_script:
    - bundle config set path vendor/bundle
    - bundle install
  after_script:
    - rm -rf tmp/
```

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->
