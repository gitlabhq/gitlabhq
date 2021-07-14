---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

<!-- markdownlint-disable MD044 -->
<!-- vale gitlab.Spelling = NO -->
# Keyword reference for the .gitlab-ci.yml file **(FREE)**
<!-- vale gitlab.Spelling = YES -->
<!-- markdownlint-enable MD044 -->

This document lists the configuration options for your GitLab `.gitlab-ci.yml` file.

- For a quick introduction to GitLab CI/CD, follow the [quick start guide](../quick_start/index.md).
- For a collection of examples, see [GitLab CI/CD Examples](../examples/README.md).
- To view a large `.gitlab-ci.yml` file used in an enterprise, see the [`.gitlab-ci.yml` file for `gitlab`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab-ci.yml).

When you are editing your `.gitlab-ci.yml` file, you can validate it with the
[CI Lint](../lint.md) tool.

## Job keywords

A job is defined as a list of keywords that define the job's behavior.

The keywords available for jobs are:

| Keyword                             | Description |
| :-----------------------------------|:------------|
| [`after_script`](#after_script)     | Override a set of commands that are executed after job. |
| [`allow_failure`](#allow_failure)   | Allow job to fail. A failed job does not cause the pipeline to fail. |
| [`artifacts`](#artifacts)           | List of files and directories to attach to a job on success. |
| [`before_script`](#before_script)   | Override a set of commands that are executed before job. |
| [`cache`](#cache)                   | List of files that should be cached between subsequent runs. |
| [`coverage`](#coverage)             | Code coverage settings for a given job. |
| [`dependencies`](#dependencies)     | Restrict which artifacts are passed to a specific job by providing a list of jobs to fetch artifacts from. |
| [`environment`](#environment)       | Name of an environment to which the job deploys. |
| [`except`](#only--except)           | Control when jobs are not created. |
| [`extends`](#extends)               | Configuration entries that this job inherits from. |
| [`image`](#image)                   | Use Docker images. |
| [`include`](#include)               | Include external YAML files. |
| [`inherit`](#inherit)               | Select which global defaults all jobs inherit. |
| [`interruptible`](#interruptible)   | Defines if a job can be canceled when made redundant by a newer run. |
| [`needs`](#needs)                   | Execute jobs earlier than the stage ordering. |
| [`only`](#only--except)             | Control when jobs are created. |
| [`pages`](#pages)                   | Upload the result of a job to use with GitLab Pages. |
| [`parallel`](#parallel)             | How many instances of a job should be run in parallel. |
| [`release`](#release)               | Instructs the runner to generate a [release](../../user/project/releases/index.md) object. |
| [`resource_group`](#resource_group) | Limit job concurrency. |
| [`retry`](#retry)                   | When and how many times a job can be auto-retried in case of a failure. |
| [`rules`](#rules)                   | List of conditions to evaluate and determine selected attributes of a job, and whether or not it's created. |
| [`script`](#script)                 | Shell script that is executed by a runner. |
| [`secrets`](#secrets)               | The CI/CD secrets the job needs. |
| [`services`](#services)             | Use Docker services images. |
| [`stage`](#stage)                   | Defines a job stage. |
| [`tags`](#tags)                     | List of tags that are used to select a runner. |
| [`timeout`](#timeout)               | Define a custom job-level timeout that takes precedence over the project-wide setting. |
| [`trigger`](#trigger)               | Defines a downstream pipeline trigger. |
| [`variables`](#variables)           | Define job variables on a job level. |
| [`when`](#when)                     | When to run job. |

### Unavailable names for jobs

You can't use these keywords as job names:

- `image`
- `services`
- `stages`
- `types`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`

### Custom default keyword values

You can set global defaults for some keywords. Jobs that do not define one or more
of the listed keywords use the value defined in the `default:` section.

These job keywords can be defined inside a `default:` section:

- [`after_script`](#after_script)
- [`artifacts`](#artifacts)
- [`before_script`](#before_script)
- [`cache`](#cache)
- [`image`](#image)
- [`interruptible`](#interruptible)
- [`retry`](#retry)
- [`services`](#services)
- [`tags`](#tags)
- [`timeout`](#timeout)

The following example sets the `ruby:3.0` image as the default for all jobs in the pipeline.
The `rspec 2.7` job does not use the default, because it overrides the default with
a job-specific `image:` section:

```yaml
default:
  image: ruby:3.0

rspec:
  script: bundle exec rspec

rspec 2.7:
  image: ruby:2.7
  script: bundle exec rspec
```

## Global keywords

Some keywords are not defined in a job. These keywords control pipeline behavior
or import additional pipeline configuration:

| Keyword                 | Description |
|-------------------------|:------------|
| [`stages`](#stages)     | The names and order of the pipeline stages. |
| [`workflow`](#workflow) | Control what types of pipeline run. |
| [`include`](#include)   | Import configuration from other YAML files. |

### `stages`

Use `stages` to define stages that contain groups of jobs. `stages` is defined globally
for the pipeline. Use [`stage`](#stage) in a job to define which stage the job is
part of.

The order of the `stages` items defines the execution order for jobs:

- Jobs in the same stage run in parallel.
- Jobs in the next stage run after the jobs from the previous stage complete successfully.

For example:

```yaml
stages:
  - build
  - test
  - deploy
```

1. All jobs in `build` execute in parallel.
1. If all jobs in `build` succeed, the `test` jobs execute in parallel.
1. If all jobs in `test` succeed, the `deploy` jobs execute in parallel.
1. If all jobs in `deploy` succeed, the pipeline is marked as `passed`.

If any job fails, the pipeline is marked as `failed` and jobs in later stages do not
start. Jobs in the current stage are not stopped and continue to run.

If no `stages` are defined in the `.gitlab-ci.yml` file, then `build`, `test` and `deploy`
are the default pipeline stages.

If a job does not specify a [`stage`](#stage), the job is assigned the `test` stage.

If a stage is defined, but no jobs use it, the stage is not visible in the pipeline. This is
useful for [compliance pipeline configuration](../../user/project/settings/index.md#compliance-pipeline-configuration)
because:

- Stages can be defined in the compliance configuration but remain hidden if not used.
- The defined stages become visible when developers use them in job definitions.

To make a job start earlier and ignore the stage order, use
the [`needs`](#needs) keyword.

### `workflow`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29654) in GitLab 12.5

Use `workflow:` to determine whether or not a pipeline is created.
Define this keyword at the top level, with a single `rules:` keyword that
is similar to [`rules:` defined in jobs](#rules).

You can use the [`workflow:rules` templates](#workflowrules-templates) to import
a preconfigured `workflow: rules` entry.

`workflow: rules` accepts these keywords:

- [`if`](#rulesif): Check this rule to determine when to run a pipeline.
- [`when`](#when): Specify what to do when the `if` rule evaluates to true.
  - To run a pipeline, set to `always`.
  - To prevent pipelines from running, set to `never`.
- [`variables`](#workflowrulesvariables): If not defined, uses the [variables defined elsewhere](#variables).

When no rules evaluate to true, the pipeline does not run.

Some example `if` clauses for `workflow: rules`:

| Example rules                                        | Details                                                   |
|------------------------------------------------------|-----------------------------------------------------------|
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | Control when merge request pipelines run.                 |
| `if: '$CI_PIPELINE_SOURCE == "push"'`                | Control when both branch pipelines and tag pipelines run. |
| `if: $CI_COMMIT_TAG`                                 | Control when tag pipelines run.                           |
| `if: $CI_COMMIT_BRANCH`                              | Control when branch pipelines run.                        |

See the [common `if` clauses for `rules`](../jobs/job_control.md#common-if-clauses-for-rules) for more examples.

In the following example, pipelines run for all `push` events (changes to
branches and new tags). Pipelines for push events with `-draft` in the commit message
don't run, because they are set to `when: never`. Pipelines for schedules or merge requests
don't run either, because no rules evaluate to true for them:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /-draft$/
      when: never
    - if: '$CI_PIPELINE_SOURCE == "push"'
```

This example has strict rules, and pipelines do **not** run in any other case.

Alternatively, all of the rules can be `when: never`, with a final
`when: always` rule. Pipelines that match the `when: never` rules do not run.
All other pipeline types run:

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: never
    - if: '$CI_PIPELINE_SOURCE == "push"'
      when: never
    - when: always
```

This example prevents pipelines for schedules or `push` (branches and tags) pipelines.
The final `when: always` rule runs all other pipeline types, **including** merge
request pipelines.

If your rules match both branch pipelines and merge request pipelines,
[duplicate pipelines](../jobs/job_control.md#avoid-duplicate-pipelines) can occur.

#### `workflow:rules:variables`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/294232) in GitLab 13.11.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/300997) in GitLab 14.1.

You can use [`variables`](#variables) in `workflow:rules:` to define variables for specific pipeline conditions.

For example:

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

#### `workflow:rules` templates

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217732) in GitLab 13.0.

GitLab provides templates that set up `workflow: rules`
for common scenarios. These templates help prevent duplicate pipelines.

The [`Branch-Pipelines` template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/Branch-Pipelines.gitlab-ci.yml)
makes your pipelines run for branches and tags.

Branch pipeline status is displayed in merge requests that use the branch
as a source. However, this pipeline type does not support any features offered by
[merge request pipelines](../pipelines/merge_request_pipelines.md), like
[pipelines for merged results](../pipelines/pipelines_for_merged_results.md)
or [merge trains](../pipelines/merge_trains.md).
This template intentionally avoids those features.

To [include](#include) it:

```yaml
include:
  - template: 'Workflows/Branch-Pipelines.gitlab-ci.yml'
```

The [`MergeRequest-Pipelines` template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/MergeRequest-Pipelines.gitlab-ci.yml)
makes your pipelines run for the default branch, tags, and
all types of merge request pipelines. Use this template if you use any of the
the [pipelines for merge requests features](../pipelines/merge_request_pipelines.md).

To [include](#include) it:

```yaml
include:
  - template: 'Workflows/MergeRequest-Pipelines.gitlab-ci.yml'
```

#### Switch between branch pipelines and merge request pipelines

> [Introduced in](https://gitlab.com/gitlab-org/gitlab/-/issues/201845) GitLab 13.8.

To make the pipeline switch from branch pipelines to merge request pipelines after
a merge request is created, add a `workflow: rules` section to your `.gitlab-ci.yml` file.

If you use both pipeline types at the same time, [duplicate pipelines](../jobs/job_control.md#avoid-duplicate-pipelines)
might run at the same time. To prevent duplicate pipelines, use the
[`CI_OPEN_MERGE_REQUESTS` variable](../variables/predefined_variables.md).

The following example is for a project that runs branch and merge request pipelines only,
but does not run pipelines for any other case. It runs:

- Branch pipelines when a merge request is not open for the branch.
- Merge request pipelines when a merge request is open for the branch.

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS'
      when: never
    - if: '$CI_COMMIT_BRANCH'
```

If the pipeline is triggered by:

- A merge request, run a merge request pipeline. For example, a merge request pipeline
  can be triggered by a push to a branch with an associated open merge request.
- A change to a branch, but a merge request is open for that branch, do not run a branch pipeline.
- A change to a branch, but without any open merge requests, run a branch pipeline.

You can also add a rule to an existing `workflow` section to switch from branch pipelines
to merge request pipelines when a merge request is created.

Add this rule to the top of the `workflow` section, followed by the other rules that
were already present:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS && $CI_PIPELINE_SOURCE == "push"
      when: never
    - ...                # Previously defined workflow rules here
```

[Triggered pipelines](../triggers/index.md) that run on a branch have a `$CI_COMMIT_BRANCH`
set and could be blocked by a similar rule. Triggered pipelines have a pipeline source
of `trigger` or `pipeline`, so `&& $CI_PIPELINE_SOURCE == "push"` ensures the rule
does not block triggered pipelines.

### `include`

> [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/42861) to GitLab Free in 11.4.

Use `include` to include external YAML files in your CI/CD configuration.
You can break down one long `gitlab-ci.yml` file into multiple files to increase readability,
or reduce duplication of the same configuration in multiple places.

You can also store template files in a central repository and `include` them in projects.

`include` requires the external YAML file to have the extensions `.yml` or `.yaml`,
otherwise the external file is not included.

You can't use [YAML anchors](#anchors) across different YAML files sourced by `include`.
You can only refer to anchors in the same file. To reuse configuration from different
YAML files, use [`!reference` tags](#reference-tags) or the [`extends` keyword](#extends).

`include` supports the following inclusion methods:

| Keyword                          | Method                                                       |
|:--------------------------------|:------------------------------------------------------------------|
| [`local`](#includelocal)        | Include a file from the local project repository.                 |
| [`file`](#includefile)          | Include a file from a different project repository.               |
| [`remote`](#includeremote)      | Include a file from a remote URL. Must be publicly accessible.    |
| [`template`](#includetemplate)  | Include templates that are provided by GitLab.                    |

When the pipeline starts, the `.gitlab-ci.yml` file configuration included by all methods is evaluated.
The configuration is a snapshot in time and persists in the database. GitLab does not reflect any changes to
the referenced `.gitlab-ci.yml` file configuration until the next pipeline starts.

The `include` files are:

- Deep merged with those in the `.gitlab-ci.yml` file.
- Always evaluated first and merged with the content of the `.gitlab-ci.yml` file,
  regardless of the position of the `include` keyword.

NOTE:
Use merging to customize and override included CI/CD configurations with local
configurations. Local configurations in the `.gitlab-ci.yml` file override included configurations.

#### Variables with `include` **(FREE SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/284883) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/294294) in GitLab 13.9.

You can [use some predefined variables in `include` sections](../variables/where_variables_can_be_used.md#gitlab-ciyml-file)
in your `.gitlab-ci.yml` file:

```yaml
include:
  project: '$CI_PROJECT_PATH'
  file: '.compliance-gitlab-ci.yml'
```

For an example of how you can include these predefined variables, and the variables' impact on CI/CD jobs,
see this [CI/CD variable demo](https://youtu.be/4XR8gw3Pkos).

#### `include:local`

Use `include:local` to include a file that is in the same repository as the `.gitlab-ci.yml` file.
Use a full path relative to the root directory (`/`).

If you use `include:local`, make sure that both the `.gitlab-ci.yml` file and the local file
are on the same branch.

You can't include local files through Git submodules paths.

All [nested includes](#nested-includes) are executed in the scope of the same project,
so it's possible to use local, project, remote, or template includes.

Example:

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

You can also use shorter syntax to define the path:

```yaml
include: '.gitlab-ci-production.yml'
```

Use local includes instead of symbolic links.

##### `include:local` with wildcard file paths

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/25921) in GitLab 13.11.
> - [Deployed behind a feature flag](../../user/feature_flags.md), disabled by default.
> - [Enabled by default](https://gitlab.com/gitlab-org/gitlab/-/issues/327315) in GitLab 13.12.
> - Enabled on GitLab.com.
> - Recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to disable it. **(CORE ONLY)**

There can be
[risks when disabling released features](../../user/feature_flags.md#risks-when-disabling-released-features).
Refer to this feature's version history for more details.

You can use wildcard paths (`*` and `**`) with `include:local`.

Example:

```yaml
include: 'configs/*.yml'
```

When the pipeline runs, GitLab:

- Adds all `.yml` files in the `configs` directory into the pipeline configuration.
- Does not add `.yml` files in subfolders of the `configs` directory. To allow this,
  add the following configuration:

  ```yaml
  # This matches all `.yml` files in `configs` and any subfolder in it.
  include: 'configs/**.yml'

  # This matches all `.yml` files only in subfolders of `configs`.
  include: 'configs/**/*.yml'
  ```

The wildcard file paths feature is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:ci_wildcard_file_paths)
```

To disable it:

```ruby
Feature.disable(:ci_wildcard_file_paths)
```

#### `include:file`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53903) in GitLab 11.7.

To include files from another private project on the same GitLab instance,
use `include:file`. You can use `include:file` in combination with `include:project` only.
Use a full path, relative to the root directory (`/`).

For example:

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
```

You can also specify a `ref`. If you do not specify a value, the ref defaults to the `HEAD` of the project:

```yaml
include:
  - project: 'my-group/my-project'
    ref: main
    file: '/templates/.gitlab-ci-template.yml'

  - project: 'my-group/my-project'
    ref: v1.0.0
    file: '/templates/.gitlab-ci-template.yml'

  - project: 'my-group/my-project'
    ref: 787123b47f14b552955ca2786bc9542ae66fee5b  # Git SHA
    file: '/templates/.gitlab-ci-template.yml'
```

All [nested includes](#nested-includes) are executed in the scope of the target project.
You can use local (relative to target project), project, remote, or template includes.

##### Multiple files from a project

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26793) in GitLab 13.6.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/271560) in GitLab 13.8.

You can include multiple files from the same project:

```yaml
include:
  - project: 'my-group/my-project'
    ref: main
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

#### `include:remote`

Use `include:remote` with a full URL to include a file from a different location.
The remote file must be publicly accessible by an HTTP/HTTPS `GET` request, because
authentication in the remote URL is not supported. For example:

```yaml
include:
  - remote: 'https://gitlab.com/example-project/-/raw/main/.gitlab-ci.yml'
```

All [nested includes](#nested-includes) execute without context as a public user,
so you can only `include` public projects or templates.

#### `include:template`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53445) in GitLab 11.7.

Use `include:template` to include `.gitlab-ci.yml` templates that are
[shipped with GitLab](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates).

For example:

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

All [nested includes](#nested-includes) are executed only with the permission of the user,
so it's possible to use project, remote or template includes.

#### Nested includes

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/56836) in GitLab 11.9.

Use nested includes to compose a set of includes.

You can have up to 100 includes, but you can't have duplicate includes.

In [GitLab 12.4](https://gitlab.com/gitlab-org/gitlab/-/issues/28212) and later, the time limit
to resolve all files is 30 seconds.

#### Additional `includes` examples

View [additional `includes` examples](includes.md).

## Keyword details

The following topics explain how to use keywords to configure CI/CD pipelines.

### `image`

Use `image` to specify [a Docker image](../docker/using_docker_images.md#what-is-an-image) to use for the job.

For:

- Usage examples, see [Define `image` in the `.gitlab-ci.yml` file](../docker/using_docker_images.md#define-image-in-the-gitlab-ciyml-file).
- Detailed usage information, refer to [Docker integration](../docker/index.md) documentation.

#### `image:name`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `image`](../docker/using_docker_images.md#available-settings-for-image).

#### `image:entrypoint`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `image`](../docker/using_docker_images.md#available-settings-for-image).

#### `services`

Use `services` to specify a [service Docker image](../services/index.md), linked to a base image specified in [`image`](#image).

For:

- Usage examples, see [Define `services` in the `.gitlab-ci.yml` file](../services/index.md#define-services-in-the-gitlab-ciyml-file).
- Detailed usage information, refer to [Docker integration](../docker/index.md) documentation.
- Example services, see [GitLab CI/CD Services](../services/index.md).

##### `services:name`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../services/index.md#available-settings-for-services).

##### `services:alias`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../services/index.md#available-settings-for-services).

##### `services:entrypoint`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../services/index.md#available-settings-for-services).

##### `services:command`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../services/index.md#available-settings-for-services).

### `script`

Use `script` to specify a shell script for the runner to execute.

All jobs except [trigger jobs](#trigger) require a `script` keyword.

For example:

```yaml
job:
  script: "bundle exec rspec"
```

You can use [YAML anchors with `script`](#yaml-anchors-for-scripts).

The `script` keyword can also contain several commands in an array:

```yaml
job:
  script:
    - uname -a
    - bundle exec rspec
```

Sometimes, `script` commands must be wrapped in single or double quotes.
For example, commands that contain a colon (`:`) must be wrapped in single quotes (`'`).
The YAML parser needs to interpret the text as a string rather than
a "key: value" pair.

For example, this script uses a colon:

```yaml
job:
  script:
    - curl --request POST --header 'Content-Type: application/json' "https://gitlab/api/v4/projects"
```

To be considered valid YAML, you must wrap the entire command in single quotes. If
the command already uses single quotes, you should change them to double quotes (`"`)
if possible:

```yaml
job:
  script:
    - 'curl --request POST --header "Content-Type: application/json" "https://gitlab/api/v4/projects"'
```

You can verify the syntax is valid with the [CI Lint](../lint.md) tool.

Be careful when using these characters as well:

- `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `` ` ``.

If any of the script commands return an exit code other than zero, the job
fails and further commands are not executed. Store the exit code in a variable to
avoid this behavior:

```yaml
job:
  script:
    - false || exit_code=$?
    - if [ $exit_code -ne 0 ]; then echo "Previous command failed"; fi;
```

#### `before_script`

Use `before_script` to define an array of commands that should run before each job,
but after [artifacts](#artifacts) are restored.

Scripts you specify in `before_script` are concatenated with any scripts you specify
in the main [`script`](#script). The combine scripts execute together in a single shell.

You can overwrite a globally-defined `before_script` if you define it in a job:

```yaml
default:
  before_script:
    - echo "Execute this script in all jobs that don't already have a before_script section."

job1:
  script:
    - echo "This script executes after the global before_script."

job:
  before_script:
    - echo "Execute this script instead of the global before_script."
  script:
    - echo "This script executes after the job's `before_script`"
```

You can use [YAML anchors with `before_script`](#yaml-anchors-for-scripts).

#### `after_script`

Use `after_script` to define an array of commands that run after each job,
including failed jobs.

If a job times out or is cancelled, the `after_script` commands do not execute.
An [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/15603) exists to support
executing `after_script` commands for timed-out or cancelled jobs.

Scripts you specify in `after_script` execute in a new shell, separate from any
`before_script` or `script` scripts. As a result, they:

- Have a current working directory set back to the default.
- Have no access to changes done by scripts defined in `before_script` or `script`, including:
  - Command aliases and variables exported in `script` scripts.
  - Changes outside of the working tree (depending on the runner executor), like
    software installed by a `before_script` or `script` script.
- Have a separate timeout, which is hard coded to 5 minutes. See the
  [related issue](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2716) for details.
- Don't affect the job's exit code. If the `script` section succeeds and the
  `after_script` times out or fails, the job exits with code `0` (`Job Succeeded`).

```yaml
default:
  after_script:
    - echo "Execute this script in all jobs that don't already have an after_script section."

job1:
  script:
    - echo "This script executes first. When it completes, the global after_script executes."

job:
  script:
    - echo "This script executes first. When it completes, the job's `after_script` executes."
  after_script:
    - echo "Execute this script instead of the global after_script."
```

You can use [YAML anchors with `after_script`](#yaml-anchors-for-scripts).

#### Script syntax

You can use syntax in [`script`](#script) sections to:

- [Split long commands](script.md#split-long-commands) into multiline commands.
- [Use color codes](script.md#add-color-codes-to-script-output) to make job logs easier to review.
- [Create custom collapsible sections](../jobs/index.md#custom-collapsible-sections)
  to simplify job log output.

### `stage`

Use `stage` to define which stage a job runs in. Jobs in the same
`stage` can execute in parallel (subject to [certain conditions](#use-your-own-runners)).

Jobs without a `stage` entry use the `test` stage by default. If you do not define
[`stages`](#stages) in the pipeline, you can use the 5 default stages, which execute in
this order:

- [`.pre`](#pre-and-post)
- `build`
- `test`
- `deploy`
- [`.post`](#pre-and-post)
For example:

```yaml
stages:
  - build
  - test
  - deploy

job 0:
  stage: .pre
  script: make something useful before build stage

job 1:
  stage: build
  script: make build dependencies

job 2:
  stage: build
  script: make build artifacts

job 3:
  stage: test
  script: make test

job 4:
  stage: deploy
  script: make deploy

job 5:
  stage: .post
  script: make something useful at the end of pipeline
```

#### Use your own runners

When you use your own runners, each runner runs only one job at a time by default.
Jobs can run in parallel if they run on different runners.

If you have only one runner, jobs can run in parallel if the runner's
[`concurrent` setting](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)
is greater than `1`.

#### `.pre` and `.post`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31441) in GitLab 12.4.

Use `pre` and `post` for jobs that need to run first or last in a pipeline.

- `.pre` is guaranteed to always be the first stage in a pipeline.
- `.post` is guaranteed to always be the last stage in a pipeline.

User-defined stages are executed after `.pre` and before `.post`.

You must have a job in at least one stage other than `.pre` or `.post`.

You can't change the order of `.pre` and `.post`, even if you define them out of order in the `.gitlab-ci.yml` file.
For example, the following configurations are equivalent:

```yaml
stages:
  - .pre
  - a
  - b
  - .post
```

```yaml
stages:
  - a
  - .pre
  - b
  - .post
```

```yaml
stages:
  - a
  - b
```

### `extends`

> Introduced in GitLab 11.3.

Use `extends` to reuse configuration sections. It's an alternative to [YAML anchors](#anchors)
and is a little more flexible and readable. You can use `extends` to reuse configuration
from [included configuration files](#use-extends-and-include-together).

In the following example, the `rspec` job uses the configuration from the `.tests` template job.
GitLab:

- Performs a reverse deep merge based on the keys.
- Merges the `.tests` content with the `rspec` job.
- Doesn't merge the values of the keys.

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

`.tests` in this example is a [hidden job](#hide-jobs), but it's
possible to extend configuration from regular jobs as well.

`extends` supports multi-level inheritance. You should avoid using more than three levels,
but you can use as many as eleven. The following example has two levels of inheritance:

```yaml
.tests:
  rules:
    - if: $CI_PIPELINE_SOURCE == "push"

.rspec:
  extends: .tests
  script: rake rspec

rspec 1:
  variables:
    RSPEC_SUITE: '1'
  extends: .rspec

rspec 2:
  variables:
    RSPEC_SUITE: '2'
  extends: .rspec

spinach:
  extends: .tests
  script: rake spinach
```

In GitLab 12.0 and later, it's also possible to use multiple parents for
`extends`.

#### Merge details

You can use `extends` to merge hashes but not arrays.
The algorithm used for merge is "closest scope wins," so
keys from the last member always override anything defined on other
levels. For example:

```yaml
.only-important:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - production
  script:
    - echo "Hello world!"

.in-docker:
  variables:
    URL: "http://docker-url.internal"
  tags:
    - docker
  image: alpine

rspec:
  variables:
    GITLAB: "is-awesome"
  extends:
    - .only-important
    - .in-docker
  script:
    - rake rspec
```

The result is this `rspec` job:

```yaml
rspec:
  variables:
    URL: "http://docker-url.internal"
    IMPORTANT_VAR: "the details"
    GITLAB: "is-awesome"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
    - if: $CI_COMMIT_BRANCH == "stable"
  tags:
    - docker
  image: alpine
  script:
    - rake rspec
```

In this example:

- The `variables` sections merge, but `URL: "http://docker-url.internal"` overwrites `URL: "http://my-url.internal"`.
- `tags: ['docker']` overwrites `tags: ['production']`.
- `script` does not merge, but `script: ['rake rspec']` overwrites
  `script: ['echo "Hello world!"']`. You can use [YAML anchors](#anchors) to merge arrays.

#### Use `extends` and `include` together

To reuse configuration from different configuration files,
combine `extends` and [`include`](#include).

In the following example, a `script` is defined in the `included.yml` file.
Then, in the `.gitlab-ci.yml` file, `extends` refers
to the contents of the `script`:

- `included.yml`:

  ```yaml
  .template:
    script:
      - echo Hello!
  ```

- `.gitlab-ci.yml`:

  ```yaml
  include: included.yml

  useTemplate:
    image: alpine
    extends: .template
  ```

### `rules`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27863) in GitLab 12.3.

Use `rules` to include or exclude jobs in pipelines.

Rules are evaluated *in order* until the first match. When a match is found, the job
is either included or excluded from the pipeline, depending on the configuration.

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

#### `rules:if`

Use `rules:if` clauses to specify when to add a job to a pipeline:

- If an `if` statement is true, add the job to the pipeline.
- If an `if` statement is true, but it's combined with `when: never`, do not add the job to the pipeline.
- If no `if` statements are true, do not add the job to the pipeline.

`if:` clauses are evaluated based on the values of [predefined CI/CD variables](../variables/predefined_variables.md)
or [custom CI/CD variables](../variables/index.md#custom-cicd-variables).

**Keyword type**: Job-specific and pipeline-specific. You can use it as part of a job
to configure the job behavior, or with [`workflow`](#workflow) to configure the pipeline behavior.

**Possible inputs**: A [CI/CD variable expression](../jobs/job_control.md#cicd-variable-expressions).

**Example of `rules:if`**:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/ && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME != $CI_DEFAULT_BRANCH'
      when: never
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/'
      when: manual
      allow_failure: true
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME'
```

**Additional details**:

- If a rule matches and has no `when` defined, the rule uses the `when`
  defined for the job, which defaults to `on_success` if not defined.
- You can define `when` once per rule, or once at the job-level, which applies to
  all rules. You can't mix `when` at the job-level with `when` in rules.
- Unlike variables in [`script`](../variables/index.md#use-cicd-variables-in-job-scripts)
  sections, variables in rules expressions are always formatted as `$VARIABLE`.

**Related topics**:

- [Common `if` expressions for `rules`](../jobs/job_control.md#common-if-clauses-for-rules).
- [Avoid duplicate pipelines](../jobs/job_control.md#avoid-duplicate-pipelines).

#### `rules:changes`

Use `rules:changes` to specify when to add a job to a pipeline by checking for changes
to specific files.

WARNING:
You should use `rules: changes` only with **branch pipelines** or **merge request pipelines**.
You can use `rules: changes` with other pipeline types, but `rules: changes` always
evaluates to true when there is no Git `push` event. Tag pipelines, scheduled pipelines,
and so on do **not** have a Git `push` event associated with them. A `rules: changes` job
is **always** added to those pipelines if there is no `if:` that limits the job to
branch or merge request pipelines.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array of file paths. In GitLab 13.6 and later,
[file paths can include variables](../jobs/job_control.md#variables-in-ruleschanges).

**Example of `rules:changes`**:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      changes:
        - Dockerfile
      when: manual
      allow_failure: true
```

- If the pipeline is a merge request pipeline, check `Dockerfile` for changes.
- If `Dockerfile` has changed, add the job to the pipeline as a manual job, and the pipeline
  continues running even if the job is not triggered (`allow_failure: true`).
- If `Dockerfile` has not changed, do not add job to any pipeline (same as `when: never`).

**Additional details**:

- `rules: changes` works the same way as [`only: changes` and `except: changes`](#onlychanges--exceptchanges).
- You can use `when: never` to implement a rule similar to [`except:changes`](#onlychanges--exceptchanges).

#### `rules:exists`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24021) in GitLab 12.4.

Use `exists` to run a job when certain files exist in the repository.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array of file paths. Paths are relative to the project directory (`$CI_PROJECT_DIR`)
and can't directly link outside it. File paths can use glob patterns.

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
- For performance reasons, GitLab matches a maximum of 10,000 `exists` patterns or
  file paths. After the 10,000th check, rules with patterned globs always match.
  In other words, the `exists` rule always assumes a match in projects with more
  than 10,000 files.

#### `rules:allow_failure`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30235) in GitLab 12.8.

Use [`allow_failure: true`](#allow_failure) in `rules:` to allow a job to fail
without stopping the pipeline.

You can also use `allow_failure: true` with a manual job. The pipeline continues
running without waiting for the result of the manual job. `allow_failure: false`
combined with `when: manual` in rules causes the pipeline to wait for the manual
job to run before continuing.

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: `true` or `false`. Defaults to `false` if not defined.

**Example of `rules:allow_failure`**:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == $CI_DEFAULT_BRANCH'
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

Use [`variables`](#variables) in `rules:` to define variables for specific conditions.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**: A hash of variables in the format `VARIABLE-NAME: value`.

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

### `only` / `except`

NOTE:
`only` and `except` are not being actively developed. [`rules`](#rules) is the preferred
keyword to control when to add jobs to pipelines.

You can use `only` and `except` to control when to add jobs to pipelines.

- Use `only` to define when a job runs.
- Use `except` to define when a job **does not** run.

Four keywords can be used with `only` and `except`:

- [`refs`](#onlyrefs--exceptrefs)
- [`variables`](#onlyvariables--exceptvariables)
- [`changes`](#onlychanges--exceptchanges)
- [`kubernetes`](#onlykubernetes--exceptkubernetes)

See [specify when jobs run with `only` and `except`](../jobs/job_control.md#specify-when-jobs-run-with-only-and-except)
for more details and examples.

#### `only:refs` / `except:refs`

Use the `only:refs` and `except:refs` keywords to control when to add jobs to a
pipeline based on branch names or pipeline types.

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
  | `merge_requests`         | For pipelines created when a merge request is created or updated. Enables [merge request pipelines](../pipelines/merge_request_pipelines.md), [merged results pipelines](../pipelines/pipelines_for_merged_results.md), and [merge trains](../pipelines/merge_trains.md). |
  | `pipelines`              | For [multi-project pipelines](../pipelines/multi_project_pipelines.md) created by [using the API with `CI_JOB_TOKEN`](../pipelines/multi_project_pipelines.md#create-multi-project-pipelines-by-using-the-api), or the [`trigger`](#trigger) keyword. |
  | `pushes`                 | For pipelines triggered by a `git push` event, including for branches and tags. |
  | `schedules`              | For [scheduled pipelines](../pipelines/schedules.md). |
  | `tags`                   | When the Git reference for a pipeline is a tag. |
  | `triggers`               | For pipelines created by using a [trigger token](../triggers/index.md#trigger-token). |
  | `web`                    | For pipelines created by using **Run pipeline** button in the GitLab UI, from the project's **CI/CD > Pipelines** section. |

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

**Additional details:**

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
    script: echo 'test'

  job2:
    script: echo 'test'
    only:
    - branches
    - tags
  ```

#### `only:variables` / `except:variables`

Use the `only:variables` or `except:variables` keywords to control when to add jobs
to a pipeline, based on the status of [CI/CD variables](../variables/index.md).

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array of [CI/CD variable expressions](../jobs/job_control.md#cicd-variable-expressions).

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

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/19232) in GitLab 11.4.

Use the `changes` keyword with `only` to run a job, or with `except` to skip a job,
when a Git push event modifies a file.

Use `changes` in pipelines with the following refs:

- `branches`
- `external_pull_requests`
- `merge_requests` (see additional details about [using `only:changes` with pipelines for merge requests](../jobs/job_control.md#use-onlychanges-with-pipelines-for-merge-requests))

**Keyword type**: Job keyword. You can use it only as part of a job.

**Possible inputs**: An array including any number of:

- Paths to files.
- Wildcard paths for single directories, for example `path/to/directory/*`, or a directory
  and all its subdirectories, for example `path/to/directory/**/*`.
- Wildcard ([glob](https://en.wikipedia.org/wiki/Glob_(programming))) paths for all
  files with the same extension or multiple extensions, for example `*.md` or `path/to/directory/*.{rb,py,sh}`.
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
```

**Additional details**:

- If you use refs other than `branches`, `external_pull_requests`, or `merge_requests`,
  `changes` can't determine if a given file is new or old and always returns `true`.
- If you use `only: changes` with other refs, jobs ignore the changes and always run.
- If you use `except: changes` with other refs, jobs ignore the changes and never run.

**Related topics**:

- [`only: changes` and `except: changes` examples](../jobs/job_control.md#onlychanges--exceptchanges-examples).
- If you use `changes` with [only allow merge requests to be merged if the pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds),
  you should [also use `only:merge_requests`](../jobs/job_control.md#use-onlychanges-with-pipelines-for-merge-requests).
- Use `changes` with [new branches or tags *without* pipelines for merge requests](../jobs/job_control.md#use-onlychanges-without-pipelines-for-merge-requests).
- Use `changes` with [scheduled pipelines](../jobs/job_control.md#use-onlychanges-with-scheduled-pipelines).

#### `only:kubernetes` / `except:kubernetes`

Use `only:kubernetes` or `except:kubernetes` to control if jobs are added to the pipeline
when the Kubernetes service is active in the project.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**: The `kubernetes` strategy accepts only the `active` keyword.

**Example of `only:kubernetes`**:

```yaml
deploy:
  only:
    kubernetes: active
```

In this example, the `deploy` job runs only when the Kubernetes service is active
in the project.

### `needs`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47063) in GitLab 12.2.
> - In GitLab 12.3, maximum number of jobs in `needs` array raised from five to 50.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30631) in GitLab 12.8, `needs: []` lets jobs start immediately.

Use `needs:` to execute jobs out-of-order. Relationships between jobs
that use `needs` can be visualized as a [directed acyclic graph](../directed_acyclic_graph/index.md).

You can ignore stage ordering and run some jobs without waiting for others to complete.
Jobs in multiple stages can run concurrently.

The following example creates four paths of execution:

- Linter: the `lint` job runs immediately without waiting for the `build` stage
  to complete because it has no needs (`needs: []`).
- Linux path: the `linux:rspec` and `linux:rubocop` jobs runs as soon as the `linux:build`
  job finishes without waiting for `mac:build` to finish.
- macOS path: the `mac:rspec` and `mac:rubocop` jobs runs as soon as the `mac:build`
  job finishes, without waiting for `linux:build` to finish.
- The `production` job runs as soon as all previous jobs finish; in this case:
  `linux:build`, `linux:rspec`, `linux:rubocop`, `mac:build`, `mac:rspec`, `mac:rubocop`.

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

linux:rubocop:
  stage: test
  needs: ["linux:build"]
  script: echo "Running rubocop on linux..."

mac:rspec:
  stage: test
  needs: ["mac:build"]
  script: echo "Running rspec on mac..."

mac:rubocop:
  stage: test
  needs: ["mac:build"]
  script: echo "Running rubocop on mac..."

production:
  stage: deploy
  script: echo "Running production..."
```

#### Requirements and limitations

- In GitLab 13.9 and older, if `needs:` refers to a job that might not be added to
  a pipeline because of `only`, `except`, or `rules`, the pipeline might fail to create.
- The maximum number of jobs that a single job can need in the `needs:` array is limited:
  - For GitLab.com, the limit is 50. For more information, see our
    [infrastructure issue](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/7541).
  - For self-managed instances, the limit is: 50. This limit [can be changed](#changing-the-needs-job-limit).
- If `needs:` refers to a job that uses the [`parallel`](#parallel) keyword,
  it depends on all jobs created in parallel, not just one job. It also downloads
  artifacts from all the parallel jobs by default. If the artifacts have the same
  name, they overwrite each other and only the last one downloaded is saved.
- `needs:` is similar to `dependencies:` in that it must use jobs from prior stages,
  meaning it's impossible to create circular dependencies. Depending on jobs in the
  current stage is not possible either, but support [is planned](https://gitlab.com/gitlab-org/gitlab/-/issues/30632).
- Stages must be explicitly defined for all jobs
  that have the keyword `needs:` or are referred to by one.

##### Changing the `needs:` job limit **(FREE SELF)**

The maximum number of jobs that can be defined in `needs:` defaults to 50.

A GitLab administrator with [access to the GitLab Rails console](../../administration/feature_flags.md)
can choose a custom limit. For example, to set the limit to 100:

```ruby
Plan.default.actual_limits.update!(ci_needs_size_limit: 100)
```

To disable directed acyclic graphs (DAG), set the limit to `0`.

#### Artifact downloads with `needs`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14311) in GitLab v12.6.

When a job uses `needs`, it no longer downloads all artifacts from previous stages
by default, because jobs with `needs` can start before earlier stages complete. With
`needs` you can only download artifacts from the jobs listed in the `needs:` configuration.

Use `artifacts: true` (default) or `artifacts: false` to control when artifacts are
downloaded in jobs that use `needs`.

In the following example, the `rspec` job downloads the `build_job` artifacts, but the
`rubocop` job does not:

```yaml
build_job:
  stage: build
  artifacts:
    paths:
      - binaries/

rspec:
  stage: test
  needs:
    - job: build_job
      artifacts: true

rubocop:
  stage: test
  needs:
    - job: build_job
      artifacts: false
```

In the following example, the `rspec` job downloads the artifacts from all three `build_jobs`.
`artifacts` is:

- Set to true for `build_job_1`.
- Defaults to true for both `build_job_2` and `build_job_3`.

```yaml
rspec:
  needs:
    - job: build_job_1
      artifacts: true
    - job: build_job_2
    - build_job_3
```

In GitLab 12.6 and later, you can't combine the [`dependencies`](#dependencies) keyword
with `needs`.

#### Cross project artifact downloads with `needs` **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14311) in GitLab v12.7.

Use `needs` to download artifacts from up to five jobs in pipelines:

- [On other refs in the same project](#artifact-downloads-between-pipelines-in-the-same-project).
- In different projects, groups and namespaces.

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
```

`build_job` downloads the artifacts from the latest successful `build-1` job
on the `main` branch in the `group/project-name` project. If the project is in the
same group or namespace, you can omit them from the `project:` keyword. For example,
`project: group/project-name` or `project: project-name`.

The user running the pipeline must have at least `reporter` access to the group or project, or the group/project must have public visibility.

##### Artifact downloads between pipelines in the same project

Use `needs` to download artifacts from different pipelines in the current project.
Set the `project` keyword as the current project's name, and specify a ref.

In the following example, `build_job` downloads the artifacts for the latest successful
`build-1` job with the `other-ref` ref:

```yaml
build_job:
  stage: build
  script:
    - ls -lhR
  needs:
    - project: group/same-project-name
      job: build-1
      ref: other-ref
      artifacts: true
```

CI/CD variable support for `project:`, `job:`, and `ref` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202093)
in GitLab 13.3. [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/235761) in GitLab 13.4.

For example:

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

You can't download artifacts from jobs that run in [`parallel:`](#parallel).

To download artifacts between [parent-child pipelines](../pipelines/parent_child_pipelines.md),
use [`needs:pipeline`](#artifact-downloads-to-child-pipelines).

You should not download artifacts from the same ref as a running pipeline. Concurrent
pipelines running on the same ref could override the artifacts.

#### Artifact downloads to child pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/255983) in GitLab v13.7.

A [child pipeline](../pipelines/parent_child_pipelines.md) can download artifacts from a job in
its parent pipeline or another child pipeline in the same parent-child pipeline hierarchy.

For example, with the following parent pipeline that has a job that creates some artifacts:

```yaml
create-artifact:
  stage: build
  script: echo 'sample artifact' > artifact.txt
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

A job in the child pipeline can download artifacts from the `create-artifact` job in
the parent pipeline:

```yaml
use-artifact:
  script: cat artifact.txt
  needs:
    - pipeline: $PARENT_PIPELINE_ID
      job: create-artifact
```

The `pipeline` attribute accepts a pipeline ID and it must be a pipeline present
in the same parent-child pipeline hierarchy of the given pipeline.

The `pipeline` attribute does not accept the current pipeline ID (`$CI_PIPELINE_ID`).
To download artifacts from a job in the current pipeline, use the basic form of [`needs`](#artifact-downloads-with-needs).

#### Optional `needs`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30680) in GitLab 13.10.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/323891) in GitLab 14.0.

To need a job that sometimes does not exist in the pipeline, add `optional: true`
to the `needs` configuration. If not defined, `optional: false` is the default.

Jobs that use [`rules`](#rules), [`only`, or `except`](#only--except), might
not always exist in a pipeline. When the pipeline starts, it checks the `needs`
relationships before running. Without `optional: true`, needs relationships that
point to a job that does not exist stops the pipeline from starting and causes a pipeline
error similar to:

- `'job1' job needs 'job2' job, but it was not added to the pipeline`

In this example:

- When the branch is the default branch, the `build` job exists in the pipeline, and the `rspec`
  job waits for it to complete before starting.
- When the branch is not the default branch, the `build` job does not exist in the pipeline.
  The `rspec` job runs immediately (similar to `needs: []`) because its `needs`
  relationship to the `build` job is optional.

```yaml
build:
  stage: build
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

rspec:
  stage: test
  needs:
    - job: build
      optional: true
```

### `tags`

Use `tags` to select a specific runner from the list of all runners that are
available for the project.

When you register a runner, you can specify the runner's tags, for
example `ruby`, `postgres`, `development`.

In the following example, the job is run by a runner that
has both `ruby` and `postgres` tags defined.

```yaml
job:
  tags:
    - ruby
    - postgres
```

You can use tags to run different jobs on different platforms. For
example, if you have an OS X runner with tag `osx` and a Windows runner with tag
`windows`, you can run a job on each platform:

```yaml
windows job:
  stage:
    - build
  tags:
    - windows
  script:
    - echo Hello, %USERNAME%!

osx job:
  stage:
    - build
  tags:
    - osx
  script:
    - echo "Hello, $USER!"
```

### `allow_failure`

Use `allow_failure` when you want to let a job fail without impacting the rest of the CI
suite. The default value is `false`, except for [manual](#whenmanual) jobs that use
the `when: manual` syntax.

In jobs that use [`rules:`](#rules), all jobs default to `allow_failure: false`,
*including* `when: manual` jobs.

When `allow_failure` is set to `true` and the job fails, the job shows an orange warning in the UI.
However, the logical flow of the pipeline considers the job a
success/passed, and is not blocked.

Assuming all other jobs are successful, the job's stage and its pipeline
show the same orange warning. However, the associated commit is marked as
"passed", without warnings.

In the following example, `job1` and `job2` run in parallel. If `job1`
fails, it doesn't stop the next stage from running, because it's marked with
`allow_failure: true`:

```yaml
job1:
  stage: test
  script:
    - execute_script_that_will_fail
  allow_failure: true

job2:
  stage: test
  script:
    - execute_script_that_will_succeed

job3:
  stage: deploy
  script:
    - deploy_to_staging
```

#### `allow_failure:exit_codes`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/273157) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/292024) in GitLab 13.9.

Use `allow_failure:exit_codes` to dynamically control if a job should be allowed
to fail. You can list which exit codes are not considered failures. The job fails
for any other exit code:

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

### `when`

Use `when` to implement jobs that run in case of failure or despite the
failure.

The valid values of `when` are:

1. `on_success` (default) - Execute job only when all jobs in earlier stages succeed,
    or are considered successful because they have `allow_failure: true`.
1. `on_failure` - Execute job only when at least one job in an earlier stage fails.
1. `always` - Execute job regardless of the status of jobs in earlier stages.
1. `manual` - Execute job [manually](#whenmanual).
1. `delayed` - [Delay the execution of a job](#whendelayed) for a specified duration.
    Added in GitLab 11.14.
1. `never`:
   - With job [`rules`](#rules), don't execute job.
   - With [`workflow:rules`](#workflow), don't run pipeline.

In the following example, the script:

1. Executes `cleanup_build_job` only when `build_job` fails.
1. Always executes `cleanup_job` as the last step in pipeline regardless of
   success or failure.
1. Executes `deploy_job` when you run it manually in the GitLab UI.

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

cleanup_job:
  stage: cleanup
  script:
    - cleanup after jobs
  when: always
```

#### `when:manual`

A manual job is a type of job that is not executed automatically and must be explicitly
started by a user. You might want to use manual jobs for things like deploying to production.

To make a job manual, add `when: manual` to its configuration.

When the pipeline starts, manual jobs display as skipped and do not run automatically.
They can be started from the pipeline, job, [environment](../environments/index.md#configure-manual-deployments),
and deployment views.

Manual jobs can be either optional or blocking:

- **Optional**: Manual jobs have [`allow_failure: true](#allow_failure) set by default
  and are considered optional. The status of an optional manual job does not contribute
  to the overall pipeline status. A pipeline can succeed even if all its manual jobs fail.

- **Blocking**: To make a blocking manual job, add `allow_failure: false` to its configuration.
  Blocking manual jobs stop further execution of the pipeline at the stage where the
  job is defined. To let the pipeline continue running, click **{play}** (play) on
  the blocking manual job.

  Merge requests in projects with [merge when pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md)
  enabled can't be merged with a blocked pipeline. Blocked pipelines show a status
  of **blocked**.

When you use [`rules:`](#rules), `allow_failure` defaults to `false`, including for manual jobs.

To trigger a manual job, a user must have permission to merge to the assigned branch.
You can use [protected branches](../../user/project/protected_branches.md) to more strictly
[protect manual deployments](#protecting-manual-jobs) from being run by unauthorized users.

In [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/201938) and later, you
can use `when:manual` in the same job as [`trigger`](#trigger). In GitLab 13.4 and
earlier, using them together causes the error `jobs:#{job-name} when should be on_success, on_failure or always`.

##### Protecting manual jobs **(PREMIUM)**

Use [protected environments](../environments/protected_environments.md)
to define a list of users authorized to run a manual job. You can authorize only
the users associated with a protected environment to trigger manual jobs, which can:

- More precisely limit who can deploy to an environment.
- Block a pipeline until an approved user "approves" it.

To protect a manual job:

1. Add an `environment` to the job. For example:

   ```yaml
   deploy_prod:
     stage: deploy
     script:
       - echo "Deploy to production server"
     environment:
       name: production
       url: https://example.com
     when: manual
     rules:
       - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
   ```

1. In the [protected environments settings](../environments/protected_environments.md#protecting-environments),
   select the environment (`production` in this example) and add the users, roles or groups
   that are authorized to trigger the manual job to the **Allowed to Deploy** list. Only those in
   this list can trigger this manual job, as well as GitLab administrators
   who are always able to use protected environments.

You can use protected environments with blocking manual jobs to have a list of users
allowed to approve later pipeline stages. Add `allow_failure: false` to the protected
manual job and the pipeline's next stages only run after the manual job is triggered
by authorized users.

#### `when:delayed`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/51352) in GitLab 11.4.

Use `when: delayed` to execute scripts after a waiting period, or if you want to avoid
jobs immediately entering the `pending` state.

You can set the period with `start_in` keyword. The value of `start_in` is an elapsed time in seconds, unless a unit is
provided. `start_in` must be less than or equal to one week. Examples of valid values include:

- `'5'`
- `5 seconds`
- `30 minutes`
- `1 day`
- `1 week`

When a stage includes a delayed job, the pipeline doesn't progress until the delayed job finishes.
You can use this keyword to insert delays between different stages.

The timer of a delayed job starts immediately after the previous stage completes.
Similar to other types of jobs, a delayed job's timer doesn't start unless the previous stage passes.

The following example creates a job named `timed rollout 10%` that is executed 30 minutes after the previous stage completes:

```yaml
timed rollout 10%:
  stage: deploy
  script: echo 'Rolling out 10% ...'
  when: delayed
  start_in: 30 minutes
```

To stop the active timer of a delayed job, click the **{time-out}** (**Unschedule**) button.
This job can no longer be scheduled to run automatically. You can, however, execute the job manually.

To start a delayed job immediately, click the **Play** button.
Soon GitLab Runner picks up and starts the job.

### `environment`

Use `environment` to define the [environment](../environments/index.md) that a job deploys to.
For example:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment: production
```

You can assign a value to the `environment` keyword by using:

- Plain text, like `production`.
- Variables, including CI/CD variables, predefined, secure, or variables
  defined in the `.gitlab-ci.yml` file.

You can't use variables defined in a `script` section.

If you specify an `environment` and no environment with that name exists,
an environment is created.

#### `environment:name`

Set a name for an [environment](../environments/index.md). For example:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
```

Common environment names are `qa`, `staging`, and `production`, but you can use any
name you want.

You can assign a value to the `name` keyword by using:

- Plain text, like `staging`.
- Variables, including CI/CD variables, predefined, secure, or variables
  defined in the `.gitlab-ci.yml` file.

You can't use variables defined in a `script` section.

The environment `name` can contain:

- Letters
- Digits
- Spaces
- `-`
- `_`
- `/`
- `$`
- `{`
- `}`

#### `environment:url`

Set a URL for an [environment](../environments/index.md). For example:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:main
  environment:
    name: production
    url: https://prod.example.com
```

After the job completes, you can access the URL by using a button in the merge request,
environment, or deployment pages.

You can assign a value to the `url` keyword by using:

- Plain text, like `https://prod.example.com`.
- Variables, including CI/CD variables, predefined, secure, or variables
  defined in the `.gitlab-ci.yml` file.

You can't use variables defined in a `script` section.

#### `environment:on_stop`

Closing (stopping) environments can be achieved with the `on_stop` keyword
defined under `environment`. It declares a different job that runs to close the
environment.

Read the `environment:action` section for an example.

#### `environment:action`

Use the `action` keyword to specify jobs that prepare, start, or stop environments.

| **Value** | **Description**                                                                                                                                               |
|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `start`     | Default value. Indicates that job starts the environment. The deployment is created after the job starts.                                                          |
| `prepare`   | Indicates that the job is only preparing the environment. It does not trigger deployments. [Read more about preparing environments](../environments/index.md#prepare-an-environment-without-creating-a-deployment). |
| `stop`      | Indicates that job stops deployment. See the example below.                                                                                                   |

Take for instance:

```yaml
review_app:
  stage: deploy
  script: make deploy-app
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com
    on_stop: stop_review_app

stop_review_app:
  stage: deploy
  variables:
    GIT_STRATEGY: none
  script: make delete-app
  when: manual
  environment:
    name: review/$CI_COMMIT_REF_NAME
    action: stop
```

In the above example, the `review_app` job deploys to the `review`
environment. A new `stop_review_app` job is listed under `on_stop`.
After the `review_app` job is finished, it triggers the
`stop_review_app` job based on what is defined under `when`. In this case,
it is set to `manual`, so it needs a [manual action](#whenmanual) from
the GitLab UI to run.

Also in the example, `GIT_STRATEGY` is set to `none`. If the
`stop_review_app` job is [automatically triggered](../environments/index.md#stopping-an-environment),
the runner won't try to check out the code after the branch is deleted.

The example also overwrites global variables. If your `stop` `environment` job depends
on global variables, use [anchor variables](#yaml-anchors-for-variables) when you set the `GIT_STRATEGY`
to change the job without overriding the global variables.

The `stop_review_app` job is **required** to have the following keywords defined:

- `when`, defined at either:
  - [The job level](#when).
  - [In a rules clause](#rules). If you use `rules:` and `when: manual`, you should
    also set [`allow_failure: true`](#allow_failure) so the pipeline can complete
    even if the job doesn't run.
- `environment:name`
- `environment:action`

Additionally, both jobs should have matching [`rules`](#only--except)
or [`only/except`](#only--except) configuration.

In the examples above, if the configuration is not identical:

- The `stop_review_app` job might not be included in all pipelines that include the `review_app` job.
- It is not possible to trigger the `action: stop` to stop the environment automatically.

#### `environment:auto_stop_in`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/20956) in GitLab 12.8.

The `auto_stop_in` keyword is for specifying the lifetime of the environment,
that when expired, GitLab automatically stops them.

For example,

```yaml
review_app:
  script: deploy-review-app
  environment:
    name: review/$CI_COMMIT_REF_NAME
    auto_stop_in: 1 day
```

When the environment for `review_app` is created, the environment's lifetime is set to `1 day`.
Every time the review app is deployed, that lifetime is also reset to `1 day`.

For more information, see
[the environments auto-stop documentation](../environments/index.md#stop-an-environment-after-a-certain-time-period)

#### `environment:kubernetes`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27630) in GitLab 12.6.

Use the `kubernetes` keyword to configure deployments to a
[Kubernetes cluster](../../user/project/clusters/index.md) that is associated with your project.

For example:

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

For more information, see
[Available settings for `kubernetes`](../environments/index.md#configure-kubernetes-deployments).

NOTE:
Kubernetes configuration is not supported for Kubernetes clusters
that are [managed by GitLab](../../user/project/clusters/index.md#gitlab-managed-clusters).
To follow progress on support for GitLab-managed clusters, see the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/38054).

#### `environment:deployment_tier`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300741) in GitLab 13.10.

Use the `deployment_tier` keyword to specify the tier of the deployment environment:

```yaml
deploy:
  script: echo
  environment:
    name: customer-portal
    deployment_tier: production
```

For more information,
see [Deployment tier of environments](../environments/index.md#deployment-tier-of-environments).

#### Dynamic environments

Use CI/CD [variables](../variables/index.md) to dynamically name environments.

For example:

```yaml
deploy as review app:
  stage: deploy
  script: make deploy
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com/
```

The `deploy as review app` job is marked as a deployment to dynamically
create the `review/$CI_COMMIT_REF_NAME` environment. `$CI_COMMIT_REF_NAME`
is a [CI/CD variable](../variables/index.md) set by the runner. The
`$CI_ENVIRONMENT_SLUG` variable is based on the environment name, but suitable
for inclusion in URLs. If the `deploy as review app` job runs in a branch named
`pow`, this environment would be accessible with a URL like `https://review-pow.example.com/`.

The common use case is to create dynamic environments for branches and use them
as Review Apps. You can see an example that uses Review Apps at
<https://gitlab.com/gitlab-examples/review-apps-nginx/>.

### `cache`

Use `cache` to specify a list of files and directories to
cache between jobs. You can only use paths that are in the local working copy.

Caching is shared between pipelines and jobs. Caches are restored before [artifacts](#artifacts).

Learn more about caches in [Caching in GitLab CI/CD](../caching/index.md).

#### `cache:paths`

Use the `cache:paths` keyword to choose which files or directories to cache.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**: An array of paths relative to the project directory (`$CI_PROJECT_DIR`).
You can use wildcards that use [glob](https://en.wikipedia.org/wiki/Glob_(programming))
patterns:

- In [GitLab Runner 13.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620) and later,
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

**Related topics**:

- See the [common `cache` use cases](../caching/index.md#common-use-cases-for-caches) for more
  `cache:paths` examples.

#### `cache:key`

Use the `cache:key` keyword to give each cache a unique identifying key. All jobs
that use the same cache key use the same cache, including in different pipelines.

If not set, the default key is `default`. All jobs with the `cache:` keyword but
no `cache:key` share the `default` cache.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**:

- A string.
- A [predefined variables](../variables/index.md).
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

- If you use **Windows Batch** to run your shell scripts you need to replace
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

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18986) in GitLab v12.5.

Use the `cache:key:files` keyword to generate a new key when one or two specific files
change. `cache:key:files` lets you reuse some caches, and rebuild them less often,
which speeds up subsequent pipeline runs.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**: An array of one or two file paths.

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

**Additional details**: The cache `key` is a SHA computed from the most recent commits
that changed each listed file. If neither file is changed in any commits, the
fallback key is `default`.

##### `cache:key:prefix`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18986) in GitLab v12.5.

Use `cache:key:prefix` to combine a prefix with the SHA computed for [`cache:key:files`](#cachekeyfiles).

**Keyword type**: Job-specific. You can use it only as part of a job.

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

**Additional details**: If no file in `cache:key:files` is changed in any commits,
the prefix is added to the `default` key.

#### `cache:untracked`

Use `untracked: true` to cache all files that are untracked in your Git repository:

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**: `true` or `false` (default).

**Example of `cache:untracked`**:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

**Additional details**:

- You can combine `cache:untracked` with `cache:paths` to cache all untracked files
  as well as files in the configured paths. For example:

  ```yaml
  rspec:
    script: test
    cache:
      untracked: true
      paths:
        - binaries/
  ```

#### `cache:when`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18969) in GitLab 13.5 and GitLab Runner v13.5.0.

Use `cache:when` to define when to save the cache, based on the status of the job.

**Keyword type**: Job-specific. You can use it only as part of a job.

**Possible inputs**:

- `on_success` (default): Save the cache only when the job succeeds.
- `on_failure`: Save the cache only when the job fails.
- `always`: Always save the cache.

**Example of `cache:untracked`**:

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
to the cache when the job ends. This is the `pull-push` policy (default).

To set a job to only download the cache when the job starts, but never upload changes
when the job finishes, use `cache:policy:pull`.

To set a job to only upload a cache when the job finishes, but never download the
cache when the job starts, use `cache:policy:push`.

Use the `pull` policy when you have many jobs executing in parallel that use the same cache.
This policy speeds up job execution and reduces load on the cache server. You can
use a job with the `push` policy to build the cache.

**Keyword type**: Job-specific. You can use it only as part of a job.

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

### `artifacts`

Use `artifacts` to specify a list of files and directories that are
attached to the job when it [succeeds, fails, or always](#artifactswhen).

The artifacts are sent to GitLab after the job finishes. They are
available for download in the GitLab UI if the size is not
larger than the [maximum artifact size](../../user/gitlab_com/index.md#gitlab-cicd).

By default, jobs in later stages automatically download all the artifacts created
by jobs in earlier stages. You can control artifact download behavior in jobs with
[`dependencies`](#dependencies).

When using the [`needs`](#artifact-downloads-with-needs) keyword, jobs can only download
artifacts from the jobs defined in the `needs` configuration.

Job artifacts are only collected for successful jobs by default, and
artifacts are restored after [caches](#cache).

[Read more about artifacts](../pipelines/job_artifacts.md).

#### `dependencies`

By default, all `artifacts` from previous stages
are passed to each job. However, you can use the `dependencies` keyword to
define a limited list of jobs to fetch artifacts from. You can also set a job to download no artifacts at all.

To use this feature, define `dependencies` in context of the job and pass
a list of all previous jobs the artifacts should be downloaded from.

You can define jobs from stages that were executed before the current one.
An error occurs if you define jobs from the current or an upcoming stage.

To prevent a job from downloading artifacts, define an empty array.

When you use `dependencies`, the status of the previous job is not considered.
If a job fails or it's a manual job that isn't triggered, no error occurs.

The following example defines two jobs with artifacts: `build:osx` and
`build:linux`. When the `test:osx` is executed, the artifacts from `build:osx`
are downloaded and extracted in the context of the build. The same happens
for `test:linux` and artifacts from `build:linux`.

The job `deploy` downloads artifacts from all previous jobs because of
the [stage](#stages) precedence:

```yaml
build:osx:
  stage: build
  script: make build:osx
  artifacts:
    paths:
      - binaries/

build:linux:
  stage: build
  script: make build:linux
  artifacts:
    paths:
      - binaries/

test:osx:
  stage: test
  script: make test:osx
  dependencies:
    - build:osx

test:linux:
  stage: test
  script: make test:linux
  dependencies:
    - build:linux

deploy:
  stage: deploy
  script: make deploy
```

##### When a dependent job fails

> Introduced in GitLab 10.3.

If the artifacts of the job that is set as a dependency are
[expired](#artifactsexpire_in) or
[deleted](../pipelines/job_artifacts.md#delete-job-artifacts), then
the dependent job fails.

#### `artifacts:exclude`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15122) in GitLab 13.1
> - Requires GitLab Runner 13.1

`exclude` makes it possible to prevent files from being added to an artifacts
archive.

Similar to [`artifacts:paths`](#artifactspaths), `exclude` paths are relative
to the project directory. You can use Wildcards that use
[glob](https://en.wikipedia.org/wiki/Glob_(programming)) or
[`doublestar.PathMatch`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#PathMatch) patterns.

For example, to store all files in `binaries/`, but not `*.o` files located in
subdirectories of `binaries/`:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

Unlike [`artifacts:paths`](#artifactspaths), `exclude` paths are not recursive. To exclude all of the contents of a directory, you can match them explicitly rather than matching the directory itself.

For example, to store all files in `binaries/` but nothing located in the `temp/` subdirectory:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/temp/**/*
```

Files matched by [`artifacts:untracked`](#artifactsuntracked) can be excluded using
`artifacts:exclude` too.

#### `artifacts:expire_in`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16267) in GitLab 13.0 behind a disabled feature flag, the latest job artifacts are kept regardless of expiry time.
> - [Made default behavior](https://gitlab.com/gitlab-org/gitlab/-/issues/229936) in GitLab 13.4.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/241026) in GitLab 13.8, keeping latest job artifacts can be disabled at the project level.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276583) in GitLab 13.9, keeping latest job artifacts can be disabled instance-wide.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/321323) in GitLab 13.12, the latest pipeline artifacts are kept regardless of expiry time.

Use `expire_in` to specify how long [job artifacts](../pipelines/job_artifacts.md) are stored before
they expire and are deleted. The `expire_in` setting does not affect:

- Artifacts from the latest job, unless this keeping the latest job artifacts is:
  - [Disabled at the project level](../pipelines/job_artifacts.md#keep-artifacts-from-most-recent-successful-jobs).
  - [Disabled instance-wide](../../user/admin_area/settings/continuous_integration.md#keep-the-latest-artifacts-for-all-jobs-in-the-latest-successful-pipelines).
- [Pipeline artifacts](../pipelines/pipeline_artifacts.md). It's not possible to specify an
  expiration date for these:
  - Pipeline artifacts from the latest pipeline are kept forever.
  - Other pipeline artifacts are erased after one week.

The value of `expire_in` is an elapsed time in seconds, unless a unit is provided. Valid values
include:

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

To expire artifacts one week after being uploaded:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

The expiration time period begins when the artifact is uploaded and stored on GitLab. If the expiry
time is not defined, it defaults to the
[instance wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration)
(30 days by default).

To override the expiration date and protect artifacts from being automatically deleted:

- Use the **Keep** button on the job page.
- [In GitLab 13.3 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/22761), set the value of
  `expire_in` to `never`.

After their expiry, artifacts are deleted hourly by default (using a cron job), and are not
accessible anymore.

#### `artifacts:expose_as`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15018) in GitLab 12.5.

Use the `expose_as` keyword to expose [job artifacts](../pipelines/job_artifacts.md)
in the [merge request](../../user/project/merge_requests/index.md) UI.

For example, to match a single file:

```yaml
test:
  script: ["echo 'test' > file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['file.txt']
```

With this configuration, GitLab adds a link **artifact 1** to the relevant merge request
that points to `file1.txt`. To access the link, select **View exposed artifact**
below the pipeline graph in the merge request overview.

An example that matches an entire directory:

```yaml
test:
  script: ["mkdir test && echo 'test' > test/file.txt"]
  artifacts:
    expose_as: 'artifact 1'
    paths: ['test/']
```

Note the following:

- Artifacts do not display in the merge request UI when using variables to define the `artifacts:paths`.
- A maximum of 10 job artifacts per merge request can be exposed.
- Glob patterns are unsupported.
- If a directory is specified, the link is to the job [artifacts browser](../pipelines/job_artifacts.md#download-job-artifacts) if there is more than
  one file in the directory.
- For exposed single file artifacts with `.html`, `.htm`, `.txt`, `.json`, `.xml`,
  and `.log` extensions, if [GitLab Pages](../../administration/pages/index.md) is:
  - Enabled, GitLab automatically renders the artifact.
  - Not enabled, the file is displayed in the artifacts browser.

#### `artifacts:name`

Use the `name` directive to define the name of the created artifacts
archive. You can specify a unique name for every archive. The `artifacts:name`
variable can make use of any of the [predefined variables](../variables/index.md).
The default name is `artifacts`, which becomes `artifacts.zip` when you download it.

To create an archive with a name of the current job:

```yaml
job:
  artifacts:
    name: "$CI_JOB_NAME"
    paths:
      - binaries/
```

To create an archive with a name of the current branch or tag including only
the binaries directory:

```yaml
job:
  artifacts:
    name: "$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

If your branch-name contains forward slashes
(for example `feature/my-feature`) it's advised to use `$CI_COMMIT_REF_SLUG`
instead of `$CI_COMMIT_REF_NAME` for proper naming of the artifact.

To create an archive with a name of the current job and the current branch or
tag including only the binaries directory:

```yaml
job:
  artifacts:
    name: "$CI_JOB_NAME-$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

To create an archive with a name of the current [stage](#stages) and branch name:

```yaml
job:
  artifacts:
    name: "$CI_JOB_STAGE-$CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

---

If you use **Windows Batch** to run your shell scripts you need to replace
`$` with `%`:

```yaml
job:
  artifacts:
    name: "%CI_JOB_STAGE%-%CI_COMMIT_REF_NAME%"
    paths:
      - binaries/
```

If you use **Windows PowerShell** to run your shell scripts you need to replace
`$` with `$env:`:

```yaml
job:
  artifacts:
    name: "$env:CI_JOB_STAGE-$env:CI_COMMIT_REF_NAME"
    paths:
      - binaries/
```

#### `artifacts:paths`

Paths are relative to the project directory (`$CI_PROJECT_DIR`) and can't directly
link outside it. You can use Wildcards that use [glob](https://en.wikipedia.org/wiki/Glob_(programming))
patterns and:

- In [GitLab Runner 13.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620) and later,
[`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match).
- In GitLab Runner 12.10 and earlier,
[`filepath.Match`](https://pkg.go.dev/path/filepath#Match).

To restrict which jobs a specific job fetches artifacts from, see [dependencies](#dependencies).

Send all files in `binaries` and `.config`:

```yaml
artifacts:
  paths:
    - binaries/
    - .config
```

To disable artifact passing, define the job with empty [dependencies](#dependencies):

```yaml
job:
  stage: build
  script: make build
  dependencies: []
```

You may want to create artifacts only for tagged releases to avoid filling the
build server storage with temporary build artifacts.

Create artifacts only for tags (`default-job` doesn't create artifacts):

```yaml
default-job:
  script:
    - mvn test -U
  rules:
    - if: $CI_COMMIT_BRANCH

release-job:
  script:
    - mvn package -U
  artifacts:
    paths:
      - target/*.war
  rules:
    - if: $CI_COMMIT_TAG
```

You can use wildcards for directories too. For example, if you want to get all the files inside the directories that end with `xyz`:

```yaml
job:
  artifacts:
    paths:
      - path/*xyz/*
```

#### `artifacts:public`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/49775) in GitLab 13.8
> - It's [deployed behind a feature flag](../../user/feature_flags.md), disabled by default.
> - It's disabled on GitLab.com.
> - It's recommended for production use.

Use `artifacts:public` to determine whether the job artifacts should be
publicly available.

The default for `artifacts:public` is `true` which means that the artifacts in
public pipelines are available for download by anonymous and guest users:

```yaml
artifacts:
  public: true
```

To deny read access for anonymous and guest users to artifacts in public
pipelines, set `artifacts:public` to `false`:

```yaml
artifacts:
  public: false
```

#### `artifacts:reports`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/20390) in GitLab 11.2.
> - Requires GitLab Runner 11.2 and above.

Use [`artifacts:reports`](#artifactsreports)
to collect test reports, code quality reports, and security reports from jobs.
It also exposes these reports in the GitLab UI (merge requests, pipeline views, and security dashboards).

The test reports are collected regardless of the job results (success or failure).
You can use [`artifacts:expire_in`](#artifactsexpire_in) to set up an expiration
date for their artifacts.

If you also want the ability to browse the report output files, include the
[`artifacts:paths`](#artifactspaths) keyword.

##### `artifacts:reports:api_fuzzing` **(ULTIMATE)**

> - Introduced in GitLab 13.4.
> - Requires GitLab Runner 13.4 or later.

The `api_fuzzing` report collects [API Fuzzing bugs](../../user/application_security/api_fuzzing/index.md)
as artifacts.

The collected API Fuzzing report uploads to GitLab as an artifact and is summarized in merge
requests and the pipeline view. It's also used to provide data for security dashboards.

##### `artifacts:reports:cobertura`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/3708) in GitLab 12.9.
> - Requires [GitLab Runner](https://docs.gitlab.com/runner/) 11.5 and above.

The `cobertura` report collects [Cobertura coverage XML files](../../user/project/merge_requests/test_coverage_visualization.md).
The collected Cobertura coverage reports upload to GitLab as an artifact
and display in merge requests.

Cobertura was originally developed for Java, but there are many
third party ports for other languages like JavaScript, Python, Ruby, and so on.

##### `artifacts:reports:codequality`

> - Introduced in GitLab 11.5.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/212499) to GitLab Free in 13.2.
> - Requires GitLab Runner 11.5 and above.

The `codequality` report collects [Code Quality issues](../../user/project/merge_requests/code_quality.md)
as artifacts.

The collected Code Quality report uploads to GitLab as an artifact and is summarized in merge requests.

##### `artifacts:reports:container_scanning` **(ULTIMATE)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

The `container_scanning` report collects [Container Scanning vulnerabilities](../../user/application_security/container_scanning/index.md)
as artifacts.

The collected Container Scanning report uploads to GitLab as an artifact and
is summarized in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

##### `artifacts:reports:coverage_fuzzing` **(ULTIMATE)**

> - Introduced in GitLab 13.4.
> - Requires GitLab Runner 13.4 or later.

The `coverage_fuzzing` report collects [coverage fuzzing bugs](../../user/application_security/coverage_fuzzing/index.md)
as artifacts.

The collected coverage fuzzing report uploads to GitLab as an artifact and is summarized in merge
requests and the pipeline view. It's also used to provide data for security dashboards.

##### `artifacts:reports:cluster_image_scanning` **(ULTIMATE)**

> - Introduced in GitLab 14.1.
> - Requires GitLab Runner 14.1 and above.

The `cluster_image_scanning` report collects `CLUSTER_IMAGE_SCANNING` vulnerabilities
as artifacts.

The collected `CLUSTER_IMAGE_SCANNING` report uploads to GitLab as an artifact and
is summarized in the pipeline view. It's also used to provide data for security
dashboards.

##### `artifacts:reports:dast` **(ULTIMATE)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

The `dast` report collects [DAST vulnerabilities](../../user/application_security/dast/index.md)
as artifacts.

The collected DAST report uploads to GitLab as an artifact and is summarized in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

##### `artifacts:reports:dependency_scanning` **(ULTIMATE)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.

The `dependency_scanning` report collects [Dependency Scanning vulnerabilities](../../user/application_security/dependency_scanning/index.md)
as artifacts.

The collected Dependency Scanning report uploads to GitLab as an artifact and is summarized in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

##### `artifacts:reports:dotenv`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/17066) in GitLab 12.9.
> - Requires GitLab Runner 11.5 and later.

The `dotenv` report collects a set of environment variables as artifacts.

The collected variables are registered as runtime-created variables of the job,
which is useful to [set dynamic environment URLs after a job finishes](../environments/index.md#set-dynamic-environment-urls-after-a-job-finishes).

There are a couple of exceptions to the [original dotenv rules](https://github.com/motdotla/dotenv#rules):

- The variable key can contain only letters, digits, and underscores (`_`).
- The maximum size of the `.env` file is 5 KB.
- In GitLab 13.5 and older, the maximum number of inherited variables is 10.
- In [GitLab 13.6 and later](https://gitlab.com/gitlab-org/gitlab/-/issues/247913),
  the maximum number of inherited variables is 20.
- Variable substitution in the `.env` file is not supported.
- The `.env` file can't have empty lines or comments (starting with `#`).
- Key values in the `env` file cannot have spaces or newline characters (`\n`), including when using single or double quotes.
- Quote escaping during parsing (`key = 'value'` -> `{key: "value"}`) is not supported.

##### `artifacts:reports:junit`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/20390) in GitLab 11.2.
> - Requires GitLab Runner 11.2 and above.

The `junit` report collects [JUnit report format XML files](https://www.ibm.com/docs/en/adfz/developer-for-zos/14.1.0?topic=formats-junit-xml-format)
as artifacts. Although JUnit was originally developed in Java, there are many
third party ports for other
languages like JavaScript, Python, Ruby, and so on.

See [Unit test reports](../unit_test_reports.md) for more details and examples.
Below is an example of collecting a JUnit report format XML file from Ruby's RSpec test tool:

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

The collected Unit test reports upload to GitLab as an artifact and display in merge requests.

If the JUnit tool you use exports to multiple XML files, specify
multiple test report paths within a single job to
concatenate them into a single file. Use a filename pattern (`junit: rspec-*.xml`),
an array of filenames (`junit: [rspec-1.xml, rspec-2.xml, rspec-3.xml]`), or a
combination thereof (`junit: [rspec.xml, test-results/TEST-*.xml]`).

##### `artifacts:reports:license_scanning` **(ULTIMATE)**

> - Introduced in GitLab 12.8.
> - Requires GitLab Runner 11.5 and above.

The `license_scanning` report collects [Licenses](../../user/compliance/license_compliance/index.md)
as artifacts.

The License Compliance report uploads to GitLab as an artifact and displays automatically in merge requests and the pipeline view, and provide data for security
dashboards.

##### `artifacts:reports:load_performance` **(PREMIUM)**

> - Introduced in [GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/35260) in [GitLab Premium](https://about.gitlab.com/pricing/) 13.2.
> - Requires GitLab Runner 11.5 and above.

The `load_performance` report collects [Load Performance Testing metrics](../../user/project/merge_requests/load_performance_testing.md)
as artifacts.

The report is uploaded to GitLab as an artifact and is
shown in merge requests automatically.

##### `artifacts:reports:metrics` **(PREMIUM)**

> Introduced in GitLab 11.10.

The `metrics` report collects [Metrics](../metrics_reports.md)
as artifacts.

The collected Metrics report uploads to GitLab as an artifact and displays in merge requests.

##### `artifacts:reports:browser_performance` **(PREMIUM)**

> - Introduced in GitLab 11.5.
> - Requires GitLab Runner 11.5 and above.
> - [Name changed](https://gitlab.com/gitlab-org/gitlab/-/issues/225914) from `artifacts:reports:performance` in GitLab 14.0.

The `browser_performance` report collects [Browser Performance Testing metrics](../../user/project/merge_requests/browser_performance_testing.md)
as artifacts.

The collected Browser Performance report uploads to GitLab as an artifact and displays in merge requests.

##### `artifacts:reports:requirements` **(ULTIMATE)**

> - [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/2859) in GitLab 13.1.
> - Requires GitLab Runner 11.5 and above.

The `requirements` report collects `requirements.json` files as artifacts.

The collected Requirements report uploads to GitLab as an artifact and
existing [requirements](../../user/project/requirements/index.md) are
marked as Satisfied.

##### `artifacts:reports:sast`

> - Introduced in GitLab 11.5.
> - Made [available in all tiers](https://gitlab.com/groups/gitlab-org/-/epics/2098) in GitLab 13.3.
> - Requires GitLab Runner 11.5 and above.

The `sast` report collects [SAST vulnerabilities](../../user/application_security/sast/index.md)
as artifacts.

The collected SAST report uploads to GitLab as an artifact and is summarized
in merge requests and the pipeline view. It's also used to provide data for security
dashboards.

##### `artifacts:reports:secret_detection`

> - Introduced in GitLab 13.1.
> - Made [available in all tiers](https://gitlab.com/gitlab-org/gitlab/-/issues/222788) in GitLab
    13.3.
> - Requires GitLab Runner 11.5 and above.

The `secret-detection` report collects [detected secrets](../../user/application_security/secret_detection/index.md)
as artifacts.

The collected Secret Detection report is uploaded to GitLab as an artifact and summarized
in the merge requests and pipeline view. It's also used to provide data for security
dashboards.

##### `artifacts:reports:terraform`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207528) in GitLab 13.0.
> - Requires [GitLab Runner](https://docs.gitlab.com/runner/) 11.5 and above.

The `terraform` report obtains a Terraform `tfplan.json` file. [JQ processing required to remove credentials](../../user/infrastructure/mr_integration.md#setup). The collected Terraform
plan report uploads to GitLab as an artifact and displays
in merge requests. For more information, see
[Output `terraform plan` information into a merge request](../../user/infrastructure/mr_integration.md).

#### `artifacts:untracked`

Use `artifacts:untracked` to add all Git untracked files as artifacts (along
with the paths defined in `artifacts:paths`). `artifacts:untracked` ignores configuration
in the repository's `.gitignore` file.

Send all Git untracked files:

```yaml
artifacts:
  untracked: true
```

Send all Git untracked files and files in `binaries`:

```yaml
artifacts:
  untracked: true
  paths:
    - binaries/
```

Send all untracked files but [exclude](#artifactsexclude) `*.txt`:

```yaml
artifacts:
  untracked: true
  exclude:
    - "*.txt"
```

#### `artifacts:when`

Use `artifacts:when` to upload artifacts on job failure or despite the
failure.

`artifacts:when` can be set to one of the following values:

1. `on_success` (default): Upload artifacts only when the job succeeds.
1. `on_failure`: Upload artifacts only when the job fails.
1. `always`: Always upload artifacts. Useful, for example, when
   [uploading artifacts](../unit_test_reports.md#viewing-junit-screenshots-on-gitlab) required to
   troubleshoot failing tests.

For example, to upload artifacts only when a job fails:

```yaml
job:
  artifacts:
    when: on_failure
```

### `coverage`

Use `coverage` to configure how code coverage is extracted from the
job output.

Regular expressions are the only valid kind of value expected here. So, using
surrounding `/` is mandatory to consistently and explicitly represent
a regular expression string. You must escape special characters if you want to
match them literally.

For example:

```yaml
job1:
  script: rspec
  coverage: '/Code coverage: \d+\.\d+/'
```

The coverage is shown in the UI if at least one line in the job output matches the regular expression.
If there is more than one matched line in the job output, the last line is used.
For the matched line, the first occurrence of `\d+(\.\d+)?` is the code coverage.
Leading zeros are removed.

Coverage output from [child pipelines](../pipelines/parent_child_pipelines.md) is not recorded
or displayed. Check [the related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/280818)
for more details.

### `retry`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3515) in GitLab 11.5, you can control which failures to retry on.

Use `retry` to configure how many times a job is retried in
case of a failure.

When a job fails, the job is processed again,
until the limit specified by the `retry` keyword is reached.

If `retry` is set to `2`, and a job succeeds in a second run (first retry), it is not retried.
The `retry` value must be a positive integer, from `0` to `2`
(two retries maximum, three runs in total).

The following example retries all failure cases:

```yaml
test:
  script: rspec
  retry: 2
```

By default, a job is retried on all failure cases. To have better control
over which failures to retry, `retry` can be a hash with the following keys:

- `max`: The maximum number of retries.
- `when`: The failure cases to retry.

To retry only runner system failures at maximum two times:

```yaml
test:
  script: rspec
  retry:
    max: 2
    when: runner_system_failure
```

If there is another failure, other than a runner system failure, the job
is not retried.

To retry on multiple failure cases, `when` can also be an array of failures:

```yaml
test:
  script: rspec
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
```

Possible values for `when` are:

<!--
  If you change any of the values below, make sure to update the `RETRY_WHEN_IN_DOCUMENTATION`
  array in `spec/lib/gitlab/ci/config/entry/retry_spec.rb`.
  The test there makes sure that all documented
  values are valid as a configuration option and therefore should always
  stay in sync with this documentation.
-->

- `always`: Retry on any failure (default).
- `unknown_failure`: Retry when the failure reason is unknown.
- `script_failure`: Retry when the script failed.
- `api_failure`: Retry on API failure.
- `stuck_or_timeout_failure`: Retry when the job got stuck or timed out.
- `runner_system_failure`: Retry if there is a runner system failure (for example, job setup failed).
- `missing_dependency_failure`: Retry if a dependency is missing.
- `runner_unsupported`: Retry if the runner is unsupported.
- `stale_schedule`: Retry if a delayed job could not be executed.
- `job_execution_timeout`: Retry if the script exceeded the maximum execution time set for the job.
- `archived_failure`: Retry if the job is archived and can't be run.
- `unmet_prerequisites`: Retry if the job failed to complete prerequisite tasks.
- `scheduler_failure`: Retry if the scheduler failed to assign the job to a runner.
- `data_integrity_failure`: Retry if there is a structural integrity problem detected.

You can specify the number of [retry attempts for certain stages of job execution](../runners/configure_runners.md#job-stages-attempts) using variables.

### `timeout`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14887) in GitLab 12.3.

Use `timeout` to configure a timeout for a specific job. For example:

```yaml
build:
  script: build.sh
  timeout: 3 hours 30 minutes

test:
  script: rspec
  timeout: 3h 30m
```

The job-level timeout can exceed the
[project-level timeout](../pipelines/settings.md#set-a-limit-for-how-long-jobs-can-run) but can't
exceed the runner-specific timeout.

### `parallel`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/21480) in GitLab 11.5.

Use `parallel` to configure how many instances of a job to run in parallel.
The value can be from 2 to 50.

The `parallel` keyword creates N instances of the same job that run in parallel.
They are named sequentially from `job_name 1/N` to `job_name N/N`:

```yaml
test:
  script: rspec
  parallel: 5
```

Every parallel job has a `CI_NODE_INDEX` and `CI_NODE_TOTAL`
[predefined CI/CD variable](../variables/index.md#predefined-cicd-variables) set.

Different languages and test suites have different methods to enable parallelization.
For example, use [Semaphore Test Boosters](https://github.com/renderedtext/test-boosters)
and RSpec to run Ruby tests in parallel:

```ruby
# Gemfile
source 'https://rubygems.org'

gem 'rspec'
gem 'semaphore_test_boosters'
```

```yaml
test:
  parallel: 3
  script:
    - bundle
    - bundle exec rspec_booster --job $CI_NODE_INDEX/$CI_NODE_TOTAL
```

WARNING:
Test Boosters reports usage statistics to the author.

You can then navigate to the **Jobs** tab of a new pipeline build and see your RSpec
job split into three separate jobs.

#### Parallel `matrix` jobs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15356) in GitLab 13.3.

Use `matrix:` to run a job multiple times in parallel in a single pipeline,
but with different variable values for each instance of the job.
There can be from 2 to 50 jobs.

Jobs can only run in parallel if there are multiple runners, or a single runner is
[configured to run multiple jobs concurrently](#use-your-own-runners).

Every job gets the same `CI_NODE_TOTAL` [CI/CD variable](../variables/index.md#predefined-cicd-variables) value, and a unique `CI_NODE_INDEX` value.

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
```

The following example generates 10 parallel `deploystacks` jobs, each with different values
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

The job naming style was [improved in GitLab 13.4](https://gitlab.com/gitlab-org/gitlab/-/issues/230452).

##### One-dimensional `matrix` jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/26362) in GitLab 13.5.

You can also have one-dimensional matrices with a single job:

```yaml
deploystacks:
  stage: deploy
  script:
    - bin/deploy
  parallel:
    matrix:
      - PROVIDER: [aws, ovh, gcp, vultr]
```

##### Parallel `matrix` trigger jobs

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/270957) in GitLab 13.10.

Use `matrix:` to run a [trigger](#trigger) job multiple times in parallel in a single pipeline,
but with different variable values for each instance of the job.

```yaml
deploystacks:
  stage: deploy
  trigger:
    include: path/to/child-pipeline.yml
  parallel:
    matrix:
      - PROVIDER: aws
        STACK: [monitoring, app1]
      - PROVIDER: ovh
        STACK: [monitoring, backup]
      - PROVIDER: [gcp, vultr]
        STACK: [data]
```

This example generates 6 parallel `deploystacks` trigger jobs, each with different values
for `PROVIDER` and `STACK`, and they create 6 different child pipelines with those variables.

```plaintext
deploystacks: [aws, monitoring]
deploystacks: [aws, app1]
deploystacks: [ovh, monitoring]
deploystacks: [ovh, backup]
deploystacks: [gcp, data]
deploystacks: [vultr, data]
```

### `trigger`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8997) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Free in 12.8.

Use `trigger` to define a downstream pipeline trigger. When GitLab starts a `trigger` job,
a downstream pipeline is created.

Jobs with `trigger` can only use a [limited set of keywords](../pipelines/multi_project_pipelines.md#define-multi-project-pipelines-in-your-gitlab-ciyml-file).
For example, you can't run commands with [`script`](#script), [`before_script`](#before_script),
or [`after_script`](#after_script).

You can use this keyword to create two different types of downstream pipelines:

- [Multi-project pipelines](../pipelines/multi_project_pipelines.md#define-multi-project-pipelines-in-your-gitlab-ciyml-file)
- [Child pipelines](../pipelines/parent_child_pipelines.md)

[In GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/197140/) and later, you can
view which job triggered a downstream pipeline. In the [pipeline graph](../pipelines/index.md#visualize-pipelines),
hover over the downstream pipeline job.

In [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/201938) and later, you
can use [`when:manual`](#whenmanual) in the same job as `trigger`. In GitLab 13.4 and
earlier, using them together causes the error `jobs:#{job-name} when should be on_success, on_failure or always`.
You [cannot start `manual` trigger jobs with the API](https://gitlab.com/gitlab-org/gitlab/-/issues/284086).

#### Basic `trigger` syntax for multi-project pipelines

You can configure a downstream trigger by using the `trigger` keyword
with a full path to a downstream project:

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger: my/deployment
```

#### Complex `trigger` syntax for multi-project pipelines

You can configure a branch name that GitLab uses to create
a downstream pipeline with:

```yaml
rspec:
  stage: test
  script: bundle exec rspec

staging:
  stage: deploy
  trigger:
    project: my/deployment
    branch: stable
```

To mirror the status from a triggered pipeline:

```yaml
trigger_job:
  trigger:
    project: my/project
    strategy: depend
```

To mirror the status from an upstream pipeline:

```yaml
upstream_bridge:
  stage: test
  needs:
    pipeline: other/project
```

#### `trigger` syntax for child pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/16094) in GitLab 12.7.

To create a [child pipeline](../pipelines/parent_child_pipelines.md), specify the path to the
YAML file that contains the configuration of the child pipeline:

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
```

Similar to [multi-project pipelines](../pipelines/multi_project_pipelines.md#mirror-status-of-a-triggered-pipeline-in-the-trigger-job),
it's possible to mirror the status from a triggered pipeline:

```yaml
trigger_job:
  trigger:
    include:
      - local: path/to/child-pipeline.yml
    strategy: depend
```

##### Trigger child pipeline with generated configuration file

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/35632) in GitLab 12.9.

You can also trigger a child pipeline from a [dynamically generated configuration file](../pipelines/parent_child_pipelines.md#dynamic-child-pipelines):

```yaml
generate-config:
  stage: build
  script: generate-ci-config > generated-config.yml
  artifacts:
    paths:
      - generated-config.yml

child-pipeline:
  stage: test
  trigger:
    include:
      - artifact: generated-config.yml
        job: generate-config
```

The `generated-config.yml` is extracted from the artifacts and used as the configuration
for triggering the child pipeline.

##### Trigger child pipeline with files from another project

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/205157) in GitLab 13.5.

To trigger child pipelines with files from another private project under the same
GitLab instance, use [`include:file`](#includefile):

```yaml
child-pipeline:
  trigger:
    include:
      - project: 'my-group/my-pipeline-library'
        ref: 'main'
        file: '/path/to/child-pipeline.yml'
```

#### Linking pipelines with `trigger:strategy`

By default, the `trigger` job completes with the `success` status
as soon as the downstream pipeline is created.

To force the `trigger` job to wait for the downstream (multi-project or child) pipeline to complete, use
`strategy: depend`. This setting makes the trigger job wait with a "running" status until the triggered
pipeline completes. At that point, the `trigger` job completes and displays the same status as
the downstream job.

This setting can help keep your pipeline execution linear. In the following example, jobs from
subsequent stages wait for the triggered pipeline to successfully complete before
starting, which reduces parallelization.

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
    strategy: depend
```

#### Trigger a pipeline by API call

To force a rebuild of a specific branch, tag, or commit, you can use an API call
with a trigger token.

The trigger token is different than the [`trigger`](#trigger) keyword.

[Read more in the triggers documentation.](../triggers/index.md)

### `interruptible`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32022) in GitLab 12.3.

Use `interruptible` to indicate that a running job should be canceled if made redundant by a newer pipeline run.
Defaults to `false` (uninterruptible). Jobs that have not started yet (pending) are considered interruptible
and safe to be cancelled.
This value is used only if the [automatic cancellation of redundant pipelines feature](../pipelines/settings.md#auto-cancel-redundant-pipelines)
is enabled.

When enabled, a pipeline is immediately canceled when a new pipeline starts on the same branch if either of the following is true:

- All jobs in the pipeline are set as interruptible.
- Any uninterruptible jobs have not started yet.

Set jobs as interruptible that can be safely canceled once started (for instance, a build job).

In the following example, a new pipeline run causes an existing running pipeline to be:

- Canceled, if only `step-1` is running or pending.
- Not canceled, once `step-2` starts running.

After an uninterruptible job starts running, the pipeline cannot be canceled.

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

### `resource_group`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15536) in GitLab 12.7.

Sometimes running multiple jobs or pipelines at the same time in an environment
can lead to errors during the deployment.

To avoid these errors, use the `resource_group` attribute to make sure that
the runner doesn't run certain jobs simultaneously. Resource groups behave similar
to semaphores in other programming languages.

When the `resource_group` keyword is defined for a job in the `.gitlab-ci.yml` file,
job executions are mutually exclusive across different pipelines for the same project.
If multiple jobs belonging to the same resource group are enqueued simultaneously,
only one of the jobs is picked by the runner. The other jobs wait until the
`resource_group` is free.

For example:

```yaml
deploy-to-production:
  script: deploy
  resource_group: production
```

In this case, two `deploy-to-production` jobs in two separate pipelines can never run at the same time. As a result,
you can ensure that concurrent deployments never happen to the production environment.

You can define multiple resource groups per environment. For example,
when deploying to physical devices, you may have multiple physical devices. Each device
can be deployed to, but there can be only one deployment per device at any given time.

The `resource_group` value can only contain letters, digits, `-`, `_`, `/`, `$`, `{`, `}`, `.`, and spaces.
It can't start or end with `/`.

For more information, see [Deployments Safety](../environments/deployment_safety.md).

#### Pipeline-level concurrency control with Cross-Project/Parent-Child pipelines

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/39057) in GitLab 13.9.

You can define `resource_group` for downstream pipelines that are sensitive to concurrent
executions. The [`trigger` keyword](#trigger) can trigger downstream pipelines. The
[`resource_group` keyword](#resource_group) can co-exist with it. This is useful to control the
concurrency for deployment pipelines, while running non-sensitive jobs concurrently.

The following example has two pipeline configurations in a project. When a pipeline starts running,
non-sensitive jobs are executed first and aren't affected by concurrent executions in other
pipelines. However, GitLab ensures that there are no other deployment pipelines running before
triggering a deployment (child) pipeline. If other deployment pipelines are running, GitLab waits
until those pipelines finish before running another one.

```yaml
# .gitlab-ci.yml (parent pipeline)

build:
  stage: build
  script: echo "Building..."

test:
  stage: test
  script: echo "Testing..."

deploy:
  stage: deploy
  trigger:
    include: deploy.gitlab-ci.yml
    strategy: depend
  resource_group: AWS-production
```

```yaml
# deploy.gitlab-ci.yml (child pipeline)

stages:
  - provision
  - deploy

provision:
  stage: provision
  script: echo "Provisioning..."

deployment:
  stage: deploy
  script: echo "Deploying..."
```

You must define [`strategy: depend`](#linking-pipelines-with-triggerstrategy)
with the `trigger` keyword. This ensures that the lock isn't released until the downstream pipeline
finishes.

### `release`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/19298) in GitLab 13.2.

Use `release` to create a [release](../../user/project/releases/index.md).
Requires the [`release-cli`](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs)
to be available in your GitLab Runner Docker or shell executor.

These keywords are supported:

- [`tag_name`](#releasetag_name)
- [`description`](#releasedescription)
- [`name`](#releasename) (optional)
- [`ref`](#releaseref) (optional)
- [`milestones`](#releasemilestones) (optional)
- [`released_at`](#releasereleased_at) (optional)
- [`assets:links`](#releaseassetslinks) (optional)

The release is created only if the job processes without error. If the Rails API
returns an error during release creation, the `release` job fails.

#### `release-cli` Docker image

You must specify the Docker image to use for the `release-cli`:

```yaml
image: registry.gitlab.com/gitlab-org/release-cli:latest
```

#### `release-cli` for shell executors

> [Introduced](https://gitlab.com/gitlab-org/release-cli/-/issues/21) in GitLab 13.8.

For GitLab Runner shell executors, you can download and install the `release-cli` manually for your [supported OS and architecture](https://release-cli-downloads.s3.amazonaws.com/latest/index.html).
Once installed, the `release` keyword should be available to you.

**Install on Unix/Linux**

1. Download the binary for your system, in the following example for amd64 systems:

  ```shell
  curl --location --output /usr/local/bin/release-cli "https://release-cli-downloads.s3.amazonaws.com/latest/release-cli-linux-amd64"
  ```

1. Give it permissions to execute:

  ```shell
  sudo chmod +x /usr/local/bin/release-cli
  ```

1. Verify `release-cli` is available:

  ```shell
  $ release-cli -v

  release-cli version 0.6.0
  ```

**Install on Windows PowerShell**

1. Create a folder somewhere in your system, for example `C:\GitLab\Release-CLI\bin`

  ```shell
  New-Item -Path 'C:\GitLab\Release-CLI\bin' -ItemType Directory
  ```

1. Download the executable file:

  ```shell
  PS C:\> Invoke-WebRequest -Uri "https://release-cli-downloads.s3.amazonaws.com/latest/release-cli-windows-amd64.exe" -OutFile "C:\GitLab\Release-CLI\bin\release-cli.exe"

      Directory: C:\GitLab\Release-CLI
  Mode                LastWriteTime         Length Name
  ----                -------------         ------ ----
  d-----        3/16/2021   4:17 AM                bin

  ```

1. Add the directory to your `$env:PATH`:

  ```shell
  $env:PATH += ";C:\GitLab\Release-CLI\bin"
  ```

1. Verify `release-cli` is available:

  ```shell
  PS C:\> release-cli -v

  release-cli version 0.6.0
  ```

#### Use a custom SSL CA certificate authority

You can use the `ADDITIONAL_CA_CERT_BUNDLE` CI/CD variable to configure a custom SSL CA certificate authority,
which is used to verify the peer when the `release-cli` creates a release through the API using HTTPS with custom certificates.
The `ADDITIONAL_CA_CERT_BUNDLE` value should contain the
[text representation of the X.509 PEM public-key certificate](https://tools.ietf.org/html/rfc7468#section-5.1)
or the `path/to/file` containing the certificate authority.
For example, to configure this value in the `.gitlab-ci.yml` file, use the following:

```yaml
release:
  variables:
    ADDITIONAL_CA_CERT_BUNDLE: |
        -----BEGIN CERTIFICATE-----
        MIIGqTCCBJGgAwIBAgIQI7AVxxVwg2kch4d56XNdDjANBgkqhkiG9w0BAQsFADCB
        ...
        jWgmPqF3vUbZE0EyScetPJquRFRKIesyJuBFMAs=
        -----END CERTIFICATE-----
  script:
    - echo "Create release"
  release:
    name: 'My awesome release'
    tag_name: '$CI_COMMIT_TAG'
```

The `ADDITIONAL_CA_CERT_BUNDLE` value can also be configured as a
[custom variable in the UI](../variables/index.md#custom-cicd-variables),
either as a `file`, which requires the path to the certificate, or as a variable,
which requires the text representation of the certificate.

#### `script`

All jobs except [trigger](#trigger) jobs must have the `script` keyword. A `release`
job can use the output from script commands, but you can use a placeholder script if
the script is not needed:

```yaml
script:
  - echo 'release job'
```

An [issue](https://gitlab.com/gitlab-org/gitlab/-/issues/223856) exists to remove this requirement in an upcoming version of GitLab.

A pipeline can have multiple `release` jobs, for example:

```yaml
ios-release:
  script:
    - echo 'iOS release job'
  release:
    tag_name: v1.0.0-ios
    description: 'iOS release v1.0.0'

android-release:
  script:
    - echo 'Android release job'
  release:
    tag_name: v1.0.0-android
    description: 'Android release v1.0.0'
```

#### `release:tag_name`

You must specify a `tag_name` for the release. The tag can refer to an existing Git tag or
you can specify a new tag.

When the specified tag doesn't exist in the repository, a new tag is created from the associated SHA of the pipeline.

For example, when creating a release from a Git tag:

```yaml
job:
  release:
    tag_name: $CI_COMMIT_TAG
    description: 'Release description'
```

It is also possible for the release job to automatically create a new unique tag. In that case,
do not use [`rules`](#rules) or [`only`](#only--except) to configure the job to
only run for tags.

A semantic versioning example:

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: 'Release description'
```

- The release is created only if the job's main script succeeds.
- If the release already exists, it is not updated and the job with the `release` keyword fails.
- The `release` section executes after the `script` tag and before the `after_script`.

#### `release:name`

The release name. If omitted, it is populated with the value of `release: tag_name`.

#### `release:description`

Specifies the long description of the release. You can also specify a file that contains the
description.

##### Read description from a file

> [Introduced](https://gitlab.com/gitlab-org/release-cli/-/merge_requests/67) in GitLab 13.7.

You can specify a file in `$CI_PROJECT_DIR` that contains the description. The file must be relative
to the project directory (`$CI_PROJECT_DIR`), and if the file is a symbolic link it can't reside
outside of `$CI_PROJECT_DIR`. The `./path/to/file` and filename can't contain spaces.

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: './path/to/CHANGELOG.md'
```

#### `release:ref`

If the `release: tag_name` doesn't exist yet, the release is created from `ref`.
`ref` can be a commit SHA, another tag name, or a branch name.

#### `release:milestones`

The title of each milestone the release is associated with.

#### `release:released_at`

The date and time when the release is ready. Defaults to the current date and time if not
defined. Should be enclosed in quotes and expressed in ISO 8601 format.

```json
released_at: '2021-03-15T08:00:00Z'
```

#### `release:assets:links`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/271454) in GitLab 13.12.

Include [asset links](../../user/project/releases/index.md#release-assets) in the release.

NOTE:
Requires `release-cli` version v0.4.0 or higher.

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

#### Complete example for `release`

If you combine the previous examples for `release`, you get two options, depending on how you generate the
tags. You can't use these options together, so choose one:

- To create a release when you push a Git tag, or when you add a Git tag
  in the UI by going to **Repository > Tags**:

  ```yaml
  release_job:
    stage: release
    image: registry.gitlab.com/gitlab-org/release-cli:latest
    rules:
      - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
    script:
      - echo 'running release_job'
    release:
      name: 'Release $CI_COMMIT_TAG'
      description: 'Created using the release-cli $EXTRA_DESCRIPTION'  # $EXTRA_DESCRIPTION must be defined
      tag_name: '$CI_COMMIT_TAG'                                       # elsewhere in the pipeline.
      ref: '$CI_COMMIT_TAG'
      milestones:
        - 'm1'
        - 'm2'
        - 'm3'
      released_at: '2020-07-15T08:00:00Z'  # Optional, is auto generated if not defined, or can use a variable.
      assets: # Optional, multiple asset links
        links:
          - name: 'asset1'
            url: 'https://example.com/assets/1'
          - name: 'asset2'
            url: 'https://example.com/assets/2'
            filepath: '/pretty/url/1' # optional
            link_type: 'other' # optional
  ```

- To create a release automatically when commits are pushed or merged to the default branch,
  using a new Git tag that is defined with variables:

  NOTE:
  Environment variables set in `before_script` or `script` are not available for expanding
  in the same job. Read more about
  [potentially making variables available for expanding](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/6400).

  ```yaml
  prepare_job:
    stage: prepare                                              # This stage must run before the release stage
    rules:
      - if: $CI_COMMIT_TAG
        when: never                                             # Do not run this job when a tag is created manually
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH             # Run this job when commits are pushed or merged to the default branch
    script:
      - echo "EXTRA_DESCRIPTION=some message" >> variables.env  # Generate the EXTRA_DESCRIPTION and TAG environment variables
      - echo "TAG=v$(cat VERSION)" >> variables.env             # and append to the variables.env file
    artifacts:
      reports:
        dotenv: variables.env                                   # Use artifacts:reports:dotenv to expose the variables to other jobs

  release_job:
    stage: release
    image: registry.gitlab.com/gitlab-org/release-cli:latest
    needs:
      - job: prepare_job
        artifacts: true
    rules:
      - if: $CI_COMMIT_TAG
        when: never                                  # Do not run this job when a tag is created manually
      - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH  # Run this job when commits are pushed or merged to the default branch
    script:
      - echo 'running release_job for $TAG'
    release:
      name: 'Release $TAG'
      description: 'Created using the release-cli $EXTRA_DESCRIPTION'  # $EXTRA_DESCRIPTION and the $TAG
      tag_name: '$TAG'                                                 # variables must be defined elsewhere
      ref: '$CI_COMMIT_SHA'                                            # in the pipeline. For example, in the
      milestones:                                                      # prepare_job
        - 'm1'
        - 'm2'
        - 'm3'
      released_at: '2020-07-15T08:00:00Z'  # Optional, is auto generated if not defined, or can use a variable.
      assets:
        links:
          - name: 'asset1'
            url: 'https://example.com/assets/1'
          - name: 'asset2'
            url: 'https://example.com/assets/2'
            filepath: '/pretty/url/1' # optional
            link_type: 'other' # optional
  ```

#### Release assets as Generic packages

You can use [Generic packages](../../user/packages/generic_packages/) to host your release assets.
For a complete example, see the [Release assets as Generic packages](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs/examples/release-assets-as-generic-package/)
project.

#### `release-cli` command line

The entries under the `release` node are transformed into a `bash` command line and sent
to the Docker container, which contains the [release-cli](https://gitlab.com/gitlab-org/release-cli).
You can also call the `release-cli` directly from a `script` entry.

For example, if you use the YAML described previously:

```shell
release-cli create --name "Release $CI_COMMIT_SHA" --description "Created using the release-cli $EXTRA_DESCRIPTION" --tag-name "v${MAJOR}.${MINOR}.${REVISION}" --ref "$CI_COMMIT_SHA" --released-at "2020-07-15T08:00:00Z" --milestone "m1" --milestone "m2" --milestone "m3" --assets-link "{\"name\":\"asset1\",\"url\":\"https://example.com/assets/1\",\"link_type\":\"other\"}
```

### `secrets`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33014) in GitLab 13.4.

Use `secrets` to specify the [CI/CD Secrets](../secrets/index.md) the job needs. It should be a hash,
and the keys should be the names of the variables that are made available to the job.
The value of each secret is saved in a temporary file. This file's path is stored in these
variables.

#### `secrets:vault` **(PREMIUM)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/28321) in GitLab 13.4 and GitLab Runner 13.4.

Use `vault` to specify secrets provided by [Hashicorp's Vault](https://www.vaultproject.io/).

This syntax has multiple forms. The shortest form assumes the use of the
[KV-V2](https://www.vaultproject.io/docs/secrets/kv/kv-v2) secrets engine,
mounted at the default path `kv-v2`. The last part of the secret's path is the
field to fetch the value for:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password  # translates to secret `kv-v2/data/production/db`, field `password`
```

You can specify a custom secrets engine path by adding a suffix starting with `@`:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops  # translates to secret `ops/data/production/db`, field `password`
```

In the detailed form of the syntax, you can specify all details explicitly:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:      # translates to secret `ops/data/production/db`, field `password`
      vault:
        engine:
          name: kv-v2
          path: ops
        path: production/db
        field: password
```

#### `secrets:file` **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/250695) in GitLab 14.1 and GitLab Runner 14.1.

By default, the secret is passed to the job context as a variable of type
[`file`](../variables/index.md#cicd-variable-types). The value of the
secret is stored in a file and the variable `DATABASE_PASSWORD` contains a path to the file.

However, some software does not work with file variables and might require the secret value to be stored
directly in the environment variable. For that case, define a `file` setting:

```yaml
job:
  secrets:
    DATABASE_PASSWORD:
      vault: production/db/password@ops
      file: false
```

When you set `file: false`, no files are created for that variable. It contains the secret
itself instead.

The `file` is a setting of the secret, so it belongs directly under the variable
name level and not in the `vault` section.

### `pages`

Use `pages` to upload static content to GitLab. The content
is then published as a website. You must:

- Place any static content in a `public/` directory.
- Define [`artifacts`](#artifacts) with a path to the `public/` directory.

The following example moves all files from the root of the project to the
`public/` directory. The `.public` workaround is so `cp` does not also copy
`public/` to itself in an infinite loop:

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
```

View the [GitLab Pages user documentation](../../user/project/pages/index.md).

### `inherit`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207484) in GitLab 12.9.

Use `inherit:` to control inheritance of globally-defined defaults
and variables.

To enable or disable the inheritance of all `default:` or `variables:` keywords, use:

- `default: true` or `default: false`
- `variables: true` or `variables: false`

To inherit only a subset of `default:` keywords or `variables:`, specify what
you wish to inherit. Anything not listed is **not** inherited. Use
one of the following formats:

```yaml
inherit:
  default: [keyword1, keyword2]
  variables: [VARIABLE1, VARIABLE2]
```

Or:

```yaml
inherit:
  default:
    - keyword1
    - keyword2
  variables:
    - VARIABLE1
    - VARIABLE2
```

In the following example:

- `rubocop`:
  - inherits: Nothing.
- `rspec`:
  - inherits: the default `image` and the `WEBHOOK_URL` variable.
  - does **not** inherit: the default `before_script` and the `DOMAIN` variable.
- `capybara`:
  - inherits: the default `before_script` and `image`.
  - does **not** inherit: the `DOMAIN` and `WEBHOOK_URL` variables.
- `karma`:
  - inherits: the default `image` and `before_script`, and the `DOMAIN` variable.
  - does **not** inherit: `WEBHOOK_URL` variable.

```yaml
default:
  image: 'ruby:2.4'
  before_script:
    - echo Hello World

variables:
  DOMAIN: example.com
  WEBHOOK_URL: https://my-webhook.example.com

rubocop:
  inherit:
    default: false
    variables: false
  script: bundle exec rubocop

rspec:
  inherit:
    default: [image]
    variables: [WEBHOOK_URL]
  script: bundle exec rspec

capybara:
  inherit:
    variables: false
  script: bundle exec capybara

karma:
  inherit:
    default: true
    variables: [DOMAIN]
  script: karma
```

## `variables`

> Introduced in GitLab Runner v0.5.0.

[CI/CD variables](../variables/index.md) are configurable values that are passed to jobs.
They can be set globally and per-job.

There are two types of variables.

- [Custom variables](../variables/index.md#custom-cicd-variables):
  You can define their values in the `.gitlab-ci.yml` file, in the GitLab UI,
  or by using the API. You can also input variables in the GitLab UI when
  [running a pipeline manually](../pipelines/index.md#run-a-pipeline-manually).
- [Predefined variables](../variables/predefined_variables.md):
  These values are set by the runner itself.
  One example is `CI_COMMIT_REF_NAME`, which is the branch or tag the project is built for.

After you define a variable, you can use it in all executed commands and scripts.

Variables are meant for non-sensitive project configuration, for example:

```yaml
variables:
  DEPLOY_SITE: "https://example.com/"

deploy_job:
  stage: deploy
  script:
    - deploy-script --url $DEPLOY_SITE --path "/"

deploy_review_job:
  stage: deploy
  variables:
    REVIEW_PATH: "/review"
  script:
    - deploy-review-script --url $DEPLOY_SITE --path $REVIEW_PATH
```

You can use only integers and strings for the variable's name and value.

If you define a variable at the top level of the `gitlab-ci.yml` file, it is global,
meaning it applies to all jobs. If you define a variable in a job, it's available
to that job only.

If a variable of the same name is defined globally and for a specific job, the
[job-specific variable overrides the global variable](../variables/index.md#cicd-variable-precedence).

All YAML-defined variables are also set to any linked
[Docker service containers](../services/index.md).

You can use [YAML anchors for variables](#yaml-anchors-for-variables).

### Prefill variables in manual pipelines

> [Introduced in](https://gitlab.com/gitlab-org/gitlab/-/issues/30101) GitLab 13.7.

Use the `value` and `description` keywords to define [pipeline-level (global) variables that are prefilled](../pipelines/index.md#prefill-variables-in-manual-pipelines)
when [running a pipeline manually](../pipelines/index.md#run-a-pipeline-manually):

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging"  # Deploy to staging by default
    description: "The deployment target. Change this variable to 'canary' or 'production' if needed."
```

You cannot set job-level variables to be pre-filled when you run a pipeline manually.

### Configure runner behavior with variables

You can use [CI/CD variables](../variables/index.md) to configure how the runner processes Git requests:

- [`GIT_STRATEGY`](../runners/configure_runners.md#git-strategy)
- [`GIT_SUBMODULE_STRATEGY`](../runners/configure_runners.md#git-submodule-strategy)
- [`GIT_CHECKOUT`](../runners/configure_runners.md#git-checkout)
- [`GIT_CLEAN_FLAGS`](../runners/configure_runners.md#git-clean-flags)
- [`GIT_FETCH_EXTRA_FLAGS`](../runners/configure_runners.md#git-fetch-extra-flags)
- [`GIT_DEPTH`](../runners/configure_runners.md#shallow-cloning) (shallow cloning)
- [`GIT_CLONE_PATH`](../runners/configure_runners.md#custom-build-directories) (custom build directories)
- [`TRANSFER_METER_FREQUENCY`](../runners/configure_runners.md#artifact-and-cache-settings) (artifact/cache meter update frequency)
- [`ARTIFACT_COMPRESSION_LEVEL`](../runners/configure_runners.md#artifact-and-cache-settings) (artifact archiver compression level)
- [`CACHE_COMPRESSION_LEVEL`](../runners/configure_runners.md#artifact-and-cache-settings) (cache archiver compression level)

You can also use variables to configure how many times a runner
[attempts certain stages of job execution](../runners/configure_runners.md#job-stages-attempts).

## YAML-specific features

In your `.gitlab-ci.yml` file, you can use YAML-specific features like anchors (`&`), aliases (`*`),
and map merging (`<<`). Use these features to reduce the complexity
of the code in the `.gitlab-ci.yml` file.

Read more about the various [YAML features](https://learnxinyminutes.com/docs/yaml/).

In most cases, the [`extends` keyword](#extends) is more user friendly and you should
use it when possible.

You can use YAML anchors to merge YAML arrays.

### Anchors

YAML has a feature called 'anchors' that you can use to duplicate
content across your document.

Use anchors to duplicate or inherit properties. Use anchors with [hidden jobs](#hide-jobs)
to provide templates for your jobs. When there are duplicate keys, GitLab
performs a reverse deep merge based on the keys.

You can't use YAML anchors across multiple files when using the [`include`](#include)
keyword. Anchors are only valid in the file they were defined in. To reuse configuration
from different YAML files, use [`!reference` tags](#reference-tags) or the
[`extends` keyword](#extends).

The following example uses anchors and map merging. It creates two jobs,
`test1` and `test2`, that inherit the `.job_template` configuration, each
with their own custom `script` defined:

```yaml
.job_template: &job_configuration  # Hidden yaml configuration that defines an anchor named 'job_configuration'
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  <<: *job_configuration           # Merge the contents of the 'job_configuration' alias
  script:
    - test1 project

test2:
  <<: *job_configuration           # Merge the contents of the 'job_configuration' alias
  script:
    - test2 project
```

`&` sets up the name of the anchor (`job_configuration`), `<<` means "merge the
given hash into the current one," and `*` includes the named anchor
(`job_configuration` again). The expanded version of this example is:

```yaml
.job_template:
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test1 project

test2:
  image: ruby:2.6
  services:
    - postgres
    - redis
  script:
    - test2 project
```

You can use anchors to define two sets of services. For example, `test:postgres`
and `test:mysql` share the `script` defined in `.job_template`, but use different
`services`, defined in `.postgres_services` and `.mysql_services`:

```yaml
.job_template: &job_configuration
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services: &postgres_configuration
    - postgres
    - ruby

.mysql_services:
  services: &mysql_configuration
    - mysql
    - ruby

test:postgres:
  <<: *job_configuration
  services: *postgres_configuration
  tags:
    - postgres

test:mysql:
  <<: *job_configuration
  services: *mysql_configuration
```

The expanded version is:

```yaml
.job_template:
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services:
    - postgres
    - ruby

.mysql_services:
  services:
    - mysql
    - ruby

test:postgres:
  script:
    - test project
  services:
    - postgres
    - ruby
  tags:
    - postgres

test:mysql:
  script:
    - test project
  services:
    - mysql
    - ruby
  tags:
    - dev
```

You can see that the hidden jobs are conveniently used as templates, and
`tags: [postgres]` overwrites `tags: [dev]`.

#### YAML anchors for scripts

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23005) in GitLab 12.5.

You can use [YAML anchors](#anchors) with [script](#script), [`before_script`](#before_script),
and [`after_script`](#after_script) to use predefined commands in multiple jobs:

```yaml
.some-script-before: &some-script-before
  - echo "Execute this script first"

.some-script: &some-script
  - echo "Execute this script second"
  - echo "Execute this script too"

.some-script-after: &some-script-after
  - echo "Execute this script last"

job1:
  before_script:
    - *some-script-before
  script:
    - *some-script
    - echo "Execute something, for this job only"
  after_script:
    - *some-script-after

job2:
  script:
    - *some-script-before
    - *some-script
    - echo "Execute something else, for this job only"
    - *some-script-after
```

#### YAML anchors for variables

Use [YAML anchors](#anchors) with `variables` to repeat assignment
of variables across multiple jobs. You can also use YAML anchors when a job
requires a specific `variables` block that would otherwise override the global variables.

The following example shows how override the `GIT_STRATEGY` variable without affecting
the use of the `SAMPLE_VARIABLE` variable:

```yaml
# global variables
variables: &global-variables
  SAMPLE_VARIABLE: sample_variable_value
  ANOTHER_SAMPLE_VARIABLE: another_sample_variable_value

# a job that must set the GIT_STRATEGY variable, yet depend on global variables
job_no_git_strategy:
  stage: cleanup
  variables:
    <<: *global-variables
    GIT_STRATEGY: none
  script: echo $SAMPLE_VARIABLE
```

### Hide jobs

If you want to temporarily disable a job, rather than commenting out all the
lines where the job is defined:

```yaml
# hidden_job:
#   script:
#     - run test
```

Instead, you can start its name with a dot (`.`) and it is not processed by
GitLab CI/CD. In the following example, `.hidden_job` is ignored:

```yaml
.hidden_job:
  script:
    - run test
```

Use this feature to ignore jobs, or use the
[YAML-specific features](#yaml-specific-features) and transform the hidden jobs
into templates.

### `!reference` tags

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/266173) in GitLab 13.9.

Use the `!reference` custom YAML tag to select keyword configuration from other job
sections and reuse it in the current section. Unlike [YAML anchors](#anchors), you can
use `!reference` tags to reuse configuration from [included](#include) configuration
files as well.

In the following example, a `script` and an `after_script` from two different locations are
reused in the `test` job:

- `setup.yml`:

  ```yaml
  .setup:
    script:
      - echo creating environment
  ```

- `.gitlab-ci.yml`:

  ```yaml
  include:
    - local: setup.yml

  .teardown:
    after_script:
      - echo deleting environment

  test:
    script:
      - !reference [.setup, script]
      - echo running my own command
    after_script:
      - !reference [.teardown, after_script]
  ```

In the following example, `test-vars-1` reuses all the variables in `.vars`, while `test-vars-2`
selects a specific variable and reuses it as a new `MY_VAR` variable.

```yaml
.vars:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"

test-vars-1:
  variables: !reference [.vars, variables]
  script:
    - printenv

test-vars-2:
  variables:
    MY_VAR: !reference [.vars, variables, IMPORTANT_VAR]
  script:
    - printenv
```

You can't reuse a section that already includes a `!reference` tag. Only one level
of nesting is supported.

## Skip Pipeline

To push a commit without triggering a pipeline, add `[ci skip]` or `[skip ci]`, using any
capitalization, to your commit message.

Alternatively, if you are using Git 2.10 or later, use the `ci.skip` [Git push option](../../user/project/push_options.md#push-options-for-gitlab-cicd).
The `ci.skip` push option does not skip merge request
pipelines.

## Processing Git pushes

GitLab creates at most four branch and tag pipelines when
pushing multiple changes in a single `git push` invocation.

This limitation does not affect any of the updated merge request pipelines.
All updated merge requests have a pipeline created when using
[pipelines for merge requests](../pipelines/merge_request_pipelines.md).

## Deprecated keywords

The following keywords are deprecated.

### Globally-defined `types`

WARNING:
`types` is deprecated, and could be removed in a future release.
Use [`stages`](#stages) instead.

### Job-defined `type`

WARNING:
`type` is deprecated, and could be removed in one of the future releases.
Use [`stage`](#stage) instead.

### Globally-defined `image`, `services`, `cache`, `before_script`, `after_script`

Defining `image`, `services`, `cache`, `before_script`, and
`after_script` globally is deprecated. Support could be removed
from a future release.

Use [`default:`](#custom-default-keyword-values) instead. For example:

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
