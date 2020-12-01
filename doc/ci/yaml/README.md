---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# GitLab CI/CD pipeline configuration reference

This document lists the configuration options for your GitLab `.gitlab-ci.yml` file.

- For a quick introduction to GitLab CI/CD, follow the [quick start guide](../quick_start/README.md).
- For a collection of examples, see [GitLab CI/CD Examples](../examples/README.md).
- To view a large `.gitlab-ci.yml` file used in an enterprise, see the [`.gitlab-ci.yml` file for `gitlab`](https://gitlab.com/gitlab-org/gitlab/blob/master/.gitlab-ci.yml).

When you are editing your `.gitlab-ci.yml` file, you can validate it with the
[CI Lint](../lint.md) tool.

## Job keywords

A job is defined as a list of keywords that define the job's behavior.

The keywords available for jobs are:

| Keyword                                            | Description                                                                                                                                                                         |
|:---------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [`script`](#script)                                | Shell script that is executed by a runner.                                                                                                                                          |
| [`after_script`](#after_script)                    | Override a set of commands that are executed after job.                                                                                                                             |
| [`allow_failure`](#allow_failure)                  | Allow job to fail. A failed job does not cause the pipeline to fail.                                                                                                                                          |
| [`artifacts`](#artifacts)                          | List of files and directories to attach to a job on success. Also available: `artifacts:paths`, `artifacts:exclude`, `artifacts:expose_as`, `artifacts:name`, `artifacts:untracked`, `artifacts:when`, `artifacts:expire_in`, and `artifacts:reports`. |
| [`before_script`](#before_script)                  | Override a set of commands that are executed before job.                                                                                                                            |
| [`cache`](#cache)                                  | List of files that should be cached between subsequent runs. Also available: `cache:paths`, `cache:key`, `cache:untracked`, `cache:when`, and `cache:policy`.                       |
| [`coverage`](#coverage)                            | Code coverage settings for a given job.                                                                                                                                             |
| [`dependencies`](#dependencies)                    | Restrict which artifacts are passed to a specific job by providing a list of jobs to fetch artifacts from.                                                                          |
| [`environment`](#environment)                      | Name of an environment to which the job deploys. Also available: `environment:name`, `environment:url`, `environment:on_stop`, `environment:auto_stop_in`, and `environment:action`. |
| [`except`](#onlyexcept-basic)                      | Limit when jobs are not created. Also available: [`except:refs`, `except:kubernetes`, `except:variables`, and `except:changes`](#onlyexcept-advanced).                              |
| [`extends`](#extends)                              | Configuration entries that this job inherits from.                                                                                                                                  |
| [`image`](#image)                                  | Use Docker images. Also available: `image:name` and `image:entrypoint`.                                                                                                             |
| [`include`](#include)                              | Include external YAML files. Also available: `include:local`, `include:file`, `include:template`, and `include:remote`.                                                             |
| [`interruptible`](#interruptible)                  | Defines if a job can be canceled when made redundant by a newer run.                                                                                                                |
| [`only`](#onlyexcept-basic)                        | Limit when jobs are created. Also available: [`only:refs`, `only:kubernetes`, `only:variables`, and `only:changes`](#onlyexcept-advanced).                                          |
| [`pages`](#pages)                                  | Upload the result of a job to use with GitLab Pages.                                                                                                                                |
| [`parallel`](#parallel)                            | How many instances of a job should be run in parallel.                                                                                                                              |
| [`release`](#release)                              | Instructs the runner to generate a [Release](../../user/project/releases/index.md) object.                                                                                          |
| [`resource_group`](#resource_group)                | Limit job concurrency.                                                                                                                                                              |
| [`retry`](#retry)                                  | When and how many times a job can be auto-retried in case of a failure.                                                                                                             |
| [`rules`](#rules)                                  | List of conditions to evaluate and determine selected attributes of a job, and whether or not it's created. May not be used alongside `only`/`except`.                              |
| [`services`](#services)                            | Use Docker services images. Also available: `services:name`, `services:alias`, `services:entrypoint`, and `services:command`.                                                       |
| [`stage`](#stage)                                  | Defines a job stage (default: `test`).                                                                                                                                              |
| [`tags`](#tags)                                    | List of tags that are used to select a runner.                                                                                                                                      |
| [`timeout`](#timeout)                              | Define a custom job-level timeout that takes precedence over the project-wide setting.                                                                                              |
| [`trigger`](#trigger)                              | Defines a downstream pipeline trigger.                                                                                                                                              |
| [`variables`](#variables)                          | Define job variables on a job level.                                                                                                                                                |
| [`when`](#when)                                    | When to run job. Also available: `when:manual` and `when:delayed`.                                                                                                                  |

### Unavailable names for jobs

Each job must have a unique name, but there are a few **reserved `keywords` that
can't be used as job names**:

- `image`
- `services`
- `stages`
- `types`
- `before_script`
- `after_script`
- `variables`
- `cache`
- `include`

### Reserved keywords

If you get a validation error when using specific values (for example, `true` or `false`), try to:

- Quote them.
- Change them to a different form. For example, `/bin/true`.

## Global keywords

Some keywords are defined at a global level and affect all jobs in the pipeline.

### Global defaults

Some keywords can be set globally as the default for all jobs with the
`default:` keyword. Default keywords can then be overridden by job-specific
configuration.

The following job keywords can be defined inside a `default:` block:

- [`image`](#image)
- [`services`](#services)
- [`before_script`](#before_script)
- [`after_script`](#after_script)
- [`tags`](#tags)
- [`cache`](#cache)
- [`artifacts`](#artifacts)
- [`retry`](#retry)
- [`timeout`](#timeout)
- [`interruptible`](#interruptible)

In the following example, the `ruby:2.5` image is set as the default for all
jobs except the `rspec 2.6` job, which uses the `ruby:2.6` image:

```yaml
default:
  image: ruby:2.5

rspec:
  script: bundle exec rspec

rspec 2.6:
  image: ruby:2.6
  script: bundle exec rspec
```

#### `inherit`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/207484) in GitLab 12.9.

You can disable inheritance of globally defined defaults
and variables with the `inherit:` keyword.

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

In the example below:

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

If no `stages` are defined in `.gitlab-ci.yml`, then `build`, `test` and `deploy`
are the default pipeline stages.

If a job does not specify a [`stage`](#stage), the job is assigned the `test` stage.

To make a job start earlier and ignore the stage order, use
the [`needs`](#needs) keyword.

### `workflow:rules`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29654) in GitLab 12.5

The top-level `workflow:` keyword determines whether or not a pipeline is created.
It accepts a single `rules:` keyword that is similar to [`rules:` defined in jobs](#rules).
Use it to define what can trigger a new pipeline.

You can use the [`workflow:rules` templates](#workflowrules-templates) to import
a preconfigured `workflow: rules` entry.

`workflow: rules` accepts these keywords:

- [`if`](#rulesif): Check this rule to determine when to run a pipeline.
- [`when`](#when): Specify what to do when the `if` rule evaluates to true.
  - To run a pipeline, set to `always`.
  - To prevent pipelines from running, set to `never`.

When no rules evaluate to true, the pipeline does not run.

Some example `if` clauses for `workflow: rules`:

| Example rules                                        | Details                                                   |
|------------------------------------------------------|-----------------------------------------------------------|
| `if: '$CI_PIPELINE_SOURCE == "merge_request_event"'` | Control when merge request pipelines run.                 |
| `if: '$CI_PIPELINE_SOURCE == "push"'`                | Control when both branch pipelines and tag pipelines run. |
| `if: $CI_COMMIT_TAG`                                 | Control when tag pipelines run.                           |
| `if: $CI_COMMIT_BRANCH`                              | Control when branch pipelines run.                        |

See the [common `if` clauses for `rules`](#common-if-clauses-for-rules) for more examples.

For example, in the following configuration, pipelines run for all `push` events (changes to
branches and new tags). Pipelines for push events with `-wip` in the commit message
don't run, because they are set to `when: never`. Pipelines for schedules or merge requests
don't run either, because no rules evaluate to true for them:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /-wip$/
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
[duplicate pipelines](#prevent-duplicate-pipelines) can occur.

#### `workflow:rules` templates

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217732) in GitLab 13.0.

We provide templates that set up `workflow: rules`
for common scenarios. These templates help prevent duplicate pipelines.

The [`Branch-Pipelines` template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/Branch-Pipelines.gitlab-ci.yml)
makes your pipelines run for branches and tags.

Branch pipeline status is displayed in merge requests that use the branch
as a source. However, this pipeline type does not support any features offered by
[Merge Request Pipelines](../merge_request_pipelines/), like
[Pipelines for Merge Results](../merge_request_pipelines/#pipelines-for-merged-results)
or [Merge Trains](../merge_request_pipelines/pipelines_for_merged_results/merge_trains/).
Use this template if you are intentionally avoiding those features.

It is [included](#include) as follows:

```yaml
include:
  - template: 'Workflows/Branch-Pipelines.gitlab-ci.yml'
```

The [`MergeRequest-Pipelines` template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Workflows/MergeRequest-Pipelines.gitlab-ci.yml)
makes your pipelines run for the default branch (usually `master`), tags, and
all types of merge request pipelines. Use this template if you use any of the
the [Pipelines for Merge Requests features](../merge_request_pipelines/), as mentioned
above.

It is [included](#include) as follows:

```yaml
include:
  - template: 'Workflows/MergeRequest-Pipelines.gitlab-ci.yml'
```

### `include`

> - Introduced in [GitLab Premium](https://about.gitlab.com/pricing/) 10.5.
> - Available for Starter, Premium, and Ultimate in GitLab 10.6 and later.
> - [Moved](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/42861) to GitLab Core in 11.4.

Use the `include` keyword to include external YAML files in your CI/CD configuration.
You can break down one long `gitlab-ci.yml` into multiple files to increase readability,
or reduce duplication of the same configuration in multiple places.

You can also store template files in a central repository and `include` them in projects.

`include` requires the external YAML file to have the extensions `.yml` or `.yaml`,
otherwise the external file is not included.

You can't use [YAML anchors](#anchors) across different YAML files sourced by `include`.
You can only refer to anchors in the same file. Instead of YAML anchors, you can
use the [`extends` keyword](#extends).

`include` supports the following inclusion methods:

| Keyword                          | Method                                                       |
|:--------------------------------|:------------------------------------------------------------------|
| [`local`](#includelocal)        | Include a file from the local project repository.                 |
| [`file`](#includefile)          | Include a file from a different project repository.               |
| [`remote`](#includeremote)      | Include a file from a remote URL. Must be publicly accessible.    |
| [`template`](#includetemplate)  | Include templates that are provided by GitLab.                    |

The `include` methods do not support [variable expansion](../variables/where_variables_can_be_used.md#variables-usage).

`.gitlab-ci.yml` configuration included by all methods is evaluated at pipeline creation.
The configuration is a snapshot in time and persisted in the database. Any changes to
referenced `.gitlab-ci.yml` configuration is not reflected in GitLab until the next pipeline is created.

The files defined by `include` are:

- Deep merged with those in `.gitlab-ci.yml`.
- Always evaluated first and merged with the content of `.gitlab-ci.yml`,
  regardless of the position of the `include` keyword.

TIP: **Tip:**
Use merging to customize and override included CI/CD configurations with local
definitions. Local definitions in `.gitlab-ci.yml` override included definitions.

#### `include:local`

`include:local` includes a file from the same repository as `.gitlab-ci.yml`.
It's referenced with full paths relative to the root directory (`/`).

You can only use files that are tracked by Git on the same branch
your configuration file is on. If you `include:local`, make
sure that both `.gitlab-ci.yml` and the local file are on the same branch.

You can't include local files through Git submodules paths.

All [nested includes](#nested-includes) are executed in the scope of the same project,
so it's possible to use local, project, remote, or template includes.

Example:

```yaml
include:
  - local: '/templates/.gitlab-ci-template.yml'
```

Local includes can be used as a replacement for symbolic links that are not followed.

This can be defined as a short local include:

```yaml
include: '.gitlab-ci-production.yml'
```

#### `include:file`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53903) in GitLab 11.7.

To include files from another private project under the same GitLab instance,
use `include:file`. This file is referenced with full paths relative to the
root directory (`/`). For example:

```yaml
include:
  - project: 'my-group/my-project'
    file: '/templates/.gitlab-ci-template.yml'
```

You can also specify a `ref`. If not specified, it defaults to the `HEAD` of the project:

```yaml
include:
  - project: 'my-group/my-project'
    ref: master
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
> - It's [deployed behind a feature flag](../../user/feature_flags.md), enabled by default.
> - It's enabled on GitLab.com.
> - It's recommended for production use.
> - For GitLab self-managed instances, GitLab administrators can opt to disable it. **(CORE ONLY)**

You can include multiple files from the same project:

```yaml
include:
  - project: 'my-group/my-project'
    ref: master
    file:
      - '/templates/.builds.yml'
      - '/templates/.tests.yml'
```

Including multiple files from the same project is under development but ready for production use. It is
deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can opt to disable it.

To enable it:

```ruby
Feature.enable(:ci_include_multiple_files_from_project)
```

To disable it:

```ruby
Feature.disable(:ci_include_multiple_files_from_project)
```

#### `include:remote`

`include:remote` can be used to include a file from a different location,
using HTTP/HTTPS, referenced by the full URL. The remote file must be
publicly accessible by a GET request, because authentication schemas
in the remote URL are not supported. For example:

```yaml
include:
  - remote: 'https://gitlab.com/awesome-project/raw/master/.gitlab-ci-template.yml'
```

All [nested includes](#nested-includes) are executed without context as a public user,
so you can only `include` public projects or templates.

#### `include:template`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/53445) in GitLab 11.7.

`include:template` can be used to include `.gitlab-ci.yml` templates that are
[shipped with GitLab](https://gitlab.com/gitlab-org/gitlab/tree/master/lib/gitlab/ci/templates).

For example:

```yaml
# File sourced from GitLab's template collection
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

There is a list of [additional `includes` examples](includes.md) available.

## Keyword details

The following are detailed explanations for keywords used to configure CI/CD pipelines.

### `image`

Used to specify [a Docker image](../docker/using_docker_images.md#what-is-an-image) to use for the job.

For:

- Usage examples, see [Define `image` and `services` from `.gitlab-ci.yml`](../docker/using_docker_images.md#define-image-and-services-from-gitlab-ciyml).
- Detailed usage information, refer to [Docker integration](../docker/README.md) documentation.

#### `image:name`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `image`](../docker/using_docker_images.md#available-settings-for-image).

#### `image:entrypoint`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `image`](../docker/using_docker_images.md#available-settings-for-image).

#### `services`

Used to specify a [service Docker image](../docker/using_docker_images.md#what-is-a-service), linked to a base image specified in [`image`](#image).

For:

- Usage examples, see [Define `image` and `services` from `.gitlab-ci.yml`](../docker/using_docker_images.md#define-image-and-services-from-gitlab-ciyml).
- Detailed usage information, refer to [Docker integration](../docker/README.md) documentation.
- For example services, see [GitLab CI/CD Services](../services/README.md).

##### `services:name`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

##### `services:alias`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

##### `services:entrypoint`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

##### `services:command`

An [extended Docker configuration option](../docker/using_docker_images.md#extended-docker-configuration-options).

For more information, see [Available settings for `services`](../docker/using_docker_images.md#available-settings-for-services).

### `script`

`script` is the only required keyword that a job needs. It's a shell script
that is executed by the runner. For example:

```yaml
job:
  script: "bundle exec rspec"
```

You can use [YAML anchors with `script`](#yaml-anchors-for-scripts).

This keyword can also contain several commands in an array:

```yaml
job:
  script:
    - uname -a
    - bundle exec rspec
```

Sometimes, `script` commands must be wrapped in single or double quotes.
For example, commands that contain a colon (`:`) must be wrapped in quotes.
The YAML parser needs to interpret the text as a string rather than
a "key: value" pair. Be careful when using special characters:
`:`, `{`, `}`, `[`, `]`, `,`, `&`, `*`, `#`, `?`, `|`, `-`, `<`, `>`, `=`, `!`, `%`, `@`, `` ` ``.

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

`before_script` is used to define an array of commands that should run before each job,
but after [artifacts](#artifacts) are restored.

Scripts specified in `before_script` are concatenated with any scripts specified
in the main [`script`](#script), and executed together in a single shell.

It's possible to overwrite a globally defined `before_script` if you define it in a job:

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

`after_script` is used to define an array of commands that run after each job,
including failed jobs.

If a job times out or is cancelled, the `after_script` commands are not executed.
Support for executing `after_script` commands for timed-out or cancelled jobs
[is planned](https://gitlab.com/gitlab-org/gitlab/-/issues/15603).

Scripts specified in `after_script` are executed in a new shell, separate from any
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

You can use special syntax in [`script`](README.md#script) sections to:

- [Split long commands](script.md#split-long-commands) into multiline commands.
- [Use color codes](script.md#add-color-codes-to-script-output) to make job logs easier to review.
- [Create custom collapsible sections](../jobs/index.md#custom-collapsible-sections)
  to simplify job log output.

### `stage`

`stage` is defined per-job and relies on [`stages`](#stages), which is defined
globally. Use `stage` to define which stage a job runs in, and jobs of the same
`stage` are executed in parallel (subject to [certain conditions](#using-your-own-runners)). For example:

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

#### Using your own runners

When you use your own runners, each runner runs only one job at a time by default.
Jobs can run in parallel if they run on different runners.

If you have only one runner, jobs can run in parallel if the runner's
[`concurrent` setting](https://docs.gitlab.com/runner/configuration/advanced-configuration.html#the-global-section)
is greater than `1`.

#### `.pre` and `.post`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/31441) in GitLab 12.4.

The following stages are available to every pipeline:

- `.pre`, which is guaranteed to always be the first stage in a pipeline.
- `.post`, which is guaranteed to always be the last stage in a pipeline.

User-defined stages are executed after `.pre` and before `.post`.

A pipeline is not created if all jobs are in `.pre` or `.post` stages.

The order of `.pre` and `.post` can't be changed, even if defined out of order in `.gitlab-ci.yml`.
For example, the following are equivalent configuration:

- Configured in order:

  ```yaml
  stages:
    - .pre
    - a
    - b
    - .post
  ```

- Configured out of order:

  ```yaml
  stages:
    - a
    - .pre
    - b
    - .post
  ```

- Not explicitly configured:

  ```yaml
  stages:
    - a
    - b
  ```

### `extends`

> Introduced in GitLab 11.3.

`extends` defines entry names that a job that uses `extends`
inherits from.

It's an alternative to using [YAML anchors](#anchors) and is a little
more flexible and readable:

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

In the example above, the `rspec` job inherits from the `.tests` template job.
GitLab performs a reverse deep merge based on the keys. GitLab:

- Merges the `rspec` contents into `.tests` recursively.
- Doesn't merge the values of the keys.

The result is this `rspec` job, where `script: rake test` is overwritten by `script: rake rspec`:

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

If you do want to include the `rake test`, see [`before_script`](#before_script) or [`after_script`](#after_script).

`.tests` in this example is a [hidden job](#hide-jobs), but it's
possible to inherit from regular jobs as well.

`extends` supports multi-level inheritance. You should avoid using more than three levels,
but you can use as many as eleven. The following example has two levels of inheritance:

```yaml
.tests:
  only:
    - pushes

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

`extends` is able to merge hashes but not arrays.
The algorithm used for merge is "closest scope wins", so
keys from the last member always override anything defined on other
levels. For example:

```yaml
.only-important:
  variables:
    URL: "http://my-url.internal"
    IMPORTANT_VAR: "the details"
  only:
    - master
    - stable
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
  only:
    - master
    - stable
  tags:
    - docker
  image: alpine
  script:
    - rake rspec
```

Note that in the example above:

- `variables` sections have been merged but that `URL: "http://my-url.internal"`
has been overwritten by `URL: "http://docker-url.internal"`.
- `tags: ['production']` has been overwritten by `tags: ['docker']`.
- `script` has not been merged but rather `script: ['echo "Hello world!"']` has
  been overwritten by `script: ['rake rspec']`. Arrays can be
  merged using [YAML anchors](#anchors).

#### Using `extends` and `include` together

`extends` works across configuration files combined with `include`.

For example, if you have a local `included.yml` file:

```yaml
.template:
  script:
    - echo Hello!
```

Then, in `.gitlab-ci.yml`:

```yaml
include: included.yml

useTemplate:
  image: alpine
  extends: .template
```

This example runs a job called `useTemplate` that runs `echo Hello!` as defined in
the `.template` job, and uses the `alpine` Docker image as defined in the local job.

### `rules`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27863) in GitLab 12.3.

The `rules` keyword can be used to include or exclude jobs in pipelines.

Rules are evaluated *in order* until the first match. When matched, the job
is either included or excluded from the pipeline, depending on the configuration.
If included, the job also has [certain attributes](#rules-attributes)
added to it.

`rules` replaces [`only/except`](#onlyexcept-basic) and can't be used in conjunction with it.
If you attempt to use both keywords in the same job, the linter returns a
`key may not be used with rules` error.

#### Rules attributes

The job attributes you can use with `rules` are:

- [`when`](#when): If not defined, defaults to `when: on_success`.
  - If used as `when: delayed`, `start_in` is also required.
- [`allow_failure`](#allow_failure): If not defined, defaults to `allow_failure: false`.

If a rule evaluates to true, and `when` has any value except `never`, the job is included in the pipeline.

For example:

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: '$CI_COMMIT_BRANCH == "master"'
      when: delayed
      start_in: '3 hours'
      allow_failure: true
```

Additional job configuration may be added to rules in the future. If something
useful is not available, please [open an issue](https://gitlab.com/gitlab-org/gitlab/-/issues).

#### Rules clauses

Available rule clauses are:

| Clause                     | Description                                                                                                                        |
|----------------------------|------------------------------------------------------------------------------------------------------------------------------------|
| [`if`](#rulesif)           | Add or exclude jobs from a pipeline by evaluating an `if` statement. Similar to [`only:variables`](#onlyvariablesexceptvariables). |
| [`changes`](#ruleschanges) | Add or exclude jobs from a pipeline based on what files are changed. Same as [`only:changes`](#onlychangesexceptchanges).          |
| [`exists`](#rulesexists)   | Add or exclude jobs from a pipeline based on the presence of specific files.                                                       |

Rules are evaluated in order until a match is found. If a match is found, the attributes
are checked to see if the job should be added to the pipeline. If no attributes are defined,
the defaults are:

- `when: on_success`
- `allow_failure: false`

The job is added to the pipeline:

- If a rule matches and has `when: on_success`, `when: delayed` or `when: always`.
- If no rules match, but the last clause is `when: on_success`, `when: delayed`
  or `when: always` (with no rule).

The job is not added to the pipeline:

- If no rules match, and there is no standalone `when: on_success`, `when: delayed` or
  `when: always`.
- If a rule matches, and has `when: never` as the attribute.

For example, using `if` clauses to strictly limit when jobs run:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: manual
      allow_failure: true
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
```

In this example:

- If the pipeline is for a merge request, the first rule matches, and the job
  is added to the [merge request pipeline](../merge_request_pipelines/index.md)
  with attributes of:
  - `when: manual` (manual job)
  - `allow_failure: true` (the pipeline continues running even if the manual job is not run)
- If the pipeline is **not** for a merge request, the first rule doesn't match, and the
  second rule is evaluated.
- If the pipeline is a scheduled pipeline, the second rule matches, and the job
  is added to the scheduled pipeline. No attributes were defined, so it is added
  with:
  - `when: on_success` (default)
  - `allow_failure: false` (default)
- In **all other cases**, no rules match, so the job is **not** added to any other pipeline.

Alternatively, you can define a set of rules to exclude jobs in a few cases, but
run them in all other cases:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
      when: never
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: never
    - when: on_success
```

- If the pipeline is for a merge request, the job is **not** be added to the pipeline.
- If the pipeline is a scheduled pipeline, the job is **not** be added to the pipeline.
- In **all other cases**, the job is added to the pipeline, with `when: on_success`.

CAUTION: **Caution:**
If you use a `when:` clause as the final rule (not including `when: never`), two
simultaneous pipelines may start. Both push pipelines and merge request pipelines can
be triggered by the same event (a push to the source branch for an open merge request).
See how to [prevent duplicate pipelines](#prevent-duplicate-pipelines)
for more details.

#### Prevent duplicate pipelines

Jobs defined with `rules` can trigger multiple pipelines with the same action. You
don't have to explicitly configure rules for each type of pipeline to trigger them
accidentally. Rules that are too broad could cause simultaneous pipelines of a different
type to run unexpectedly.

Some configurations that have the potential to cause duplicate pipelines cause a
[pipeline warning](../troubleshooting.md#pipeline-warnings) to be displayed.
[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/219431) in GitLab 13.3.

For example:

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: '$CUSTOM_VARIABLE == "false"'
      when: never
    - when: always
```

This job does not run when `$CUSTOM_VARIABLE` is false, but it *does* run in **all**
other pipelines, including **both** push (branch) and merge request pipelines. With
this configuration, every push to an open merge request's source branch
causes duplicated pipelines.

There are multiple ways to avoid duplicate pipelines:

- Use [`workflow: rules`](#workflowrules) to specify which types of pipelines
  can run. To eliminate duplicate pipelines, use merge request pipelines only
  or push (branch) pipelines only.

- Rewrite the rules to run the job only in very specific cases,
  and avoid using a final `when:` rule:

  ```yaml
  job:
    script: echo "This job does NOT create double pipelines!"
    rules:
      - if: '$CUSTOM_VARIABLE == "true" && $CI_PIPELINE_SOURCE == "merge_request_event"'
  ```

You can prevent duplicate pipelines by changing the job rules to avoid either push (branch)
pipelines or merge request pipelines. However, if you use a `- when: always` rule without
`workflow: rules`, GitLab still displays a [pipeline warning](../troubleshooting.md#pipeline-warnings).

For example, the following does not trigger double pipelines, but is not recommended
without `workflow: rules`:

```yaml
job:
  script: echo "This job does NOT create double pipelines!"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push"'
      when: never
    - when: always
```

Do not include both push and merge request pipelines in the same job:

```yaml
job:
  script: echo "This job creates double pipelines!"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "push"'
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
```

Also, do not mix `only/except` jobs with `rules` jobs in the same pipeline.
It may not cause YAML errors, but the different default behaviors of `only/except`
and `rules` can cause issues that are difficult to troubleshoot:

```yaml
job-with-no-rules:
  script: echo "This job runs in branch pipelines."

job-with-rules:
  script: echo "This job runs in merge request pipelines."
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
```

For every change pushed to the branch, duplicate pipelines run. One
branch pipeline runs a single job (`job-with-no-rules`), and one merge request pipeline
runs the other job (`job-with-rules`). Jobs with no rules default
to [`except: merge_requests`](#onlyexcept-basic), so `job-with-no-rules`
runs in all cases except merge requests.

It is not possible to define rules based on whether or not a branch has an open
merge request associated with it. You can't configure a job to be included in:

- Only branch pipelines when the branch doesn't have a merge request associated with it.
- Only merge request pipelines when the branch has a merge request associated with it.

See the [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/201845) for more details.

#### `rules:if`

`rules:if` clauses determine whether or not jobs are added to a pipeline by evaluating
an `if` statement. If the `if` statement is true, the job is either included
or excluded from a pipeline. In plain English, `if` rules can be interpreted as one of:

- "If this rule evaluates to true, add the job" (default).
- "If this rule evaluates to true, do not add the job" (by adding `when: never`).

`rules:if` differs slightly from `only:variables` by accepting only a single
expression string per rule, rather than an array of them. Any set of expressions to be
evaluated can be [conjoined into a single expression](../variables/README.md#conjunction--disjunction)
by using `&&` or `||`, and the [variable matching operators (`==`, `!=`, `=~` and `!~`)](../variables/README.md#syntax-of-environment-variable-expressions).

Unlike variables in [`script`](../variables/README.md#syntax-of-environment-variables-in-job-scripts)
sections, variables in rules expressions are always formatted as `$VARIABLE`.

`if:` clauses are evaluated based on the values of [predefined environment variables](../variables/predefined_variables.md)
or [custom environment variables](../variables/README.md#custom-environment-variables).

For example:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/ && $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "master"'
      when: always
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME =~ /^feature/'
      when: manual
      allow_failure: true
    - if: '$CI_MERGE_REQUEST_SOURCE_BRANCH_NAME'  # Checking for the presence of a variable is possible
```

Some details regarding the logic that determines the `when` for the job:

- If none of the provided rules match, the job is set to `when: never` and is
  not included in the pipeline.
- A rule without any conditional clause, such as a `when` or `allow_failure`
  rule without `if` or `changes`, always matches, and is always used if reached.
- If a rule matches and has no `when` defined, the rule uses the `when`
  defined for the job, which defaults to `on_success` if not defined.
- You can define `when` once per rule, or once at the job-level, which applies to
  all rules. You can't mix `when` at the job-level with `when` in rules.

##### Common `if` clauses for `rules`

For behavior similar to the [`only`/`except` keywords](#onlyexcept-basic), you can
check the value of the `$CI_PIPELINE_SOURCE` variable:

| Value                         | Description                                                                                                                                                                                                                      |
|-------------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`                         | For pipelines triggered by the [pipelines API](../../api/pipelines.md#create-a-new-pipeline).                                                                                                                                    |
| `chat`                        | For pipelines created by using a [GitLab ChatOps](../chatops/README.md) command.                                                                                                                                                 |
| `external`                    | When using CI services other than GitLab.                                                                                                                                                                                        |
| `external_pull_request_event` | When an external pull request on GitHub is created or updated. See [Pipelines for external pull requests](../ci_cd_for_external_repos/index.md#pipelines-for-external-pull-requests).                                            |
| `merge_request_event`         | For pipelines created when a merge request is created or updated. Required to enable [merge request pipelines](../merge_request_pipelines/index.md), [merged results pipelines](../merge_request_pipelines/pipelines_for_merged_results/index.md), and [merge trains](../merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md). |
| `parent_pipeline`             | For pipelines triggered by a [parent/child pipeline](../parent_child_pipelines.md) with `rules`. Use this pipeline source in the child pipeline configuration so that it can be triggered by the parent pipeline.                |
| `pipeline`                    | For [multi-project pipelines](../multi_project_pipelines.md) created by [using the API with `CI_JOB_TOKEN`](../multi_project_pipelines.md#triggering-multi-project-pipelines-through-api), or the [`trigger`](#trigger) keyword. |
| `push`                        | For pipelines triggered by a `git push` event, including for branches and tags.                                                                                                                                                  |
| `schedule`                    | For [scheduled pipelines](../pipelines/schedules.md).                                                                                                                                                                            |
| `trigger`                     | For pipelines created by using a [trigger token](../triggers/README.md#trigger-token).                                                                                                                                           |
| `web`                         | For pipelines created by using **Run pipeline** button in the GitLab UI, from the project's **CI/CD > Pipelines** section.                                                                                                       |
| `webide`                      | For pipelines created by using the [WebIDE](../../user/project/web_ide/index.md).                                                                                                                                                |

For example:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
      when: manual
      allow_failure: true
    - if: '$CI_PIPELINE_SOURCE == "push"'
```

This example runs the job as a manual job in scheduled pipelines or in push
pipelines (to branches or tags), with `when: on_success` (default). It does not
add the job to any other pipeline type.

Another example:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_PIPELINE_SOURCE == "merge_request_event"'
    - if: '$CI_PIPELINE_SOURCE == "schedule"'
```

This example runs the job as a `when: on_success` job in [merge request pipelines](../merge_request_pipelines/index.md)
and scheduled pipelines. It does not run in any other pipeline type.

Other commonly used variables for `if` clauses:

- `if: $CI_COMMIT_TAG`: If changes are pushed for a tag.
- `if: $CI_COMMIT_BRANCH`: If changes are pushed to any branch.
- `if: '$CI_COMMIT_BRANCH == "master"'`: If changes are pushed to `master`.
- `if: '$CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH'`: If changes are pushed to the default
  branch (usually `master`). Use when you want to have the same configuration in multiple
  projects with different default branches.
- `if: '$CI_COMMIT_BRANCH =~ /regex-expression/'`: If the commit branch matches a regular expression.
- `if: '$CUSTOM_VARIABLE !~ /regex-expression/'`: If the [custom variable](../variables/README.md#custom-environment-variables)
  `CUSTOM_VARIABLE` does **not** match a regular expression.
- `if: '$CUSTOM_VARIABLE == "value1"'`: If the custom variable `CUSTOM_VARIABLE` is
  exactly `value1`.

#### `rules:changes`

`rules:changes` determines whether or not to add jobs to a pipeline by checking for
changes to specific files.

`rules: changes` works exactly the same way as [`only: changes` and `except: changes`](#onlychangesexceptchanges),
accepting an array of paths. It's recommended to only use `rules: changes` with branch
pipelines or merge request pipelines. For example, it's common to use `rules: changes`
with merge request pipelines:

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

In this example:

- If the pipeline is a merge request pipeline, check `Dockerfile` for changes.
- If `Dockerfile` has changed, add the job to the pipeline as a manual job, and the pipeline
  continues running even if the job is not triggered (`allow_failure: true`).
- If `Dockerfile` has not changed, do not add job to any pipeline (same as `when: never`).

To use `rules: changes` with branch pipelines instead of merge request pipelines,
change the `if:` clause in the example above to:

```yaml
rules:
  - if: $CI_PIPELINE_SOURCE == "push" && $CI_COMMIT_BRANCH
```

To implement a rule similar to [`except:changes`](#onlychangesexceptchanges),
use `when: never`.

CAUTION: **Caution:**
You can use `rules: changes` with other pipeline types, but it is not recommended
because `rules: changes` always evaluates to true when there is no Git `push` event.
Tag pipelines, scheduled pipelines, and so on do **not** have a Git `push` event
associated with them. A `rules: changes` job is **always** added to those pipeline
if there is no `if:` statement that limits the job to branch or merge request pipelines.

##### Variables in `rules:changes`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/34272) in GitLab 13.6.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/267192) in GitLab 13.7.

Environment variables can be used in `rules:changes` expressions to determine when
to add jobs to a pipeline:

```yaml
docker build:
  variables:
    DOCKERFILES_DIR: 'path/to/files/'
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - changes:
        - $DOCKERFILES_DIR/*
```

The `$` character can be used for both variables and paths. For example, if the
`$DOCKERFILES_DIR` variable exists, its value is used. If it does not exist, the
`$` is interpreted as being part of a path.

#### `rules:exists`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/24021) in GitLab 12.4.

`exists` accepts an array of paths and matches if any of these paths exist
as files in the repository:

```yaml
job:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - exists:
        - Dockerfile
```

You can also use glob patterns to match multiple files in any directory in the repository:

```yaml
job:
  script: bundle exec rspec
  rules:
    - exists:
        - spec/**.rb
```

For performance reasons, using `exists` with patterns is limited to 10,000
checks. After the 10,000th check, rules with patterned globs always match.

#### `rules:allow_failure`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30235) in GitLab 12.8.

You can use [`allow_failure: true`](#allow_failure) in `rules:` to allow a job to fail, or a manual job to
wait for action, without stopping the pipeline itself. All jobs using `rules:` default to `allow_failure: false`
if `allow_failure:` is not defined.

The rule-level `rules:allow_failure` option overrides the job-level
[`allow_failure`](#allow_failure) option, and is only applied when the job is
triggered by the particular rule.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: '$CI_MERGE_REQUEST_TARGET_BRANCH_NAME == "master"'
      when: manual
      allow_failure: true
```

In this example, if the first rule matches, then the job has `when: manual` and `allow_failure: true`.

#### Complex rule clauses

To conjoin `if`, `changes`, and `exists` clauses with an `AND`, use them in the
same rule.

In the following example:

- If the `Dockerfile` file or any file in `/docker/scripts` has changed, and var=blah,
  then the job runs manually
- Otherwise, the job isn't included in the pipeline.

```yaml
docker build:
  script: docker build -t my-image:$CI_COMMIT_REF_SLUG .
  rules:
    - if: '$VAR == "string value"'
      changes:  # Include the job and set to when:manual if any of the follow paths match a modified file.
        - Dockerfile
        - docker/scripts/*
      when: manual
      # - "when: never" would be redundant here. It is implied any time rules are listed.
```

Keywords such as `branches` or `refs` that are available for
`only`/`except` are not available in `rules`. They are being individually
considered for their usage and behavior in this context. Future keyword improvements
are being discussed in our [epic for improving `rules`](https://gitlab.com/groups/gitlab-org/-/epics/2783),
where anyone can add suggestions or requests.

You can use [parentheses](../variables/README.md#parentheses) with `&&` and `||` to build more complicated variable expressions.
[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230938) in GitLab 13.3:

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  rules:
    if: ($CI_COMMIT_BRANCH == "master" || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

CAUTION: **Caution:**
[Before GitLab 13.3](https://gitlab.com/gitlab-org/gitlab/-/issues/230938),
rules that use both `||` and `&&` may evaluate with an unexpected order of operations.

### `only`/`except` (basic)

NOTE: **Note:**
The [`rules`](#rules) syntax is an improved, more powerful solution for defining
when jobs should run or not. Consider using `rules` instead of `only/except` to get
the most out of your pipelines.

`only` and `except` are two keywords that set a job policy to limit when
jobs are created:

1. `only` defines the names of branches and tags the job runs for.
1. `except` defines the names of branches and tags the job does
    **not** run for.

There are a few rules that apply to the usage of job policy:

- `only` and `except` are inclusive. If both `only` and `except` are defined
   in a job specification, the ref is filtered by `only` and `except`.
- `only` and `except` can use regular expressions ([supported regexp syntax](#supported-onlyexcept-regexp-syntax)).
- `only` and `except` can specify a repository path to filter jobs for forks.

In addition, `only` and `except` can use special keywords:

| **Value**                | **Description**                                                                                                                                                                                                                  |
|--------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `api`                    | For pipelines triggered by the [pipelines API](../../api/pipelines.md#create-a-new-pipeline).                                                                                                                                    |
| `branches`               | When the Git reference for a pipeline is a branch.                                                                                                                                                                               |
| `chat`                   | For pipelines created by using a [GitLab ChatOps](../chatops/README.md) command.                                                                                                                                                 |
| `external`               | When using CI services other than GitLab.                                                                                                                                                                                        |
| `external_pull_requests` | When an external pull request on GitHub is created or updated (See [Pipelines for external pull requests](../ci_cd_for_external_repos/index.md#pipelines-for-external-pull-requests)).                                           |
| `merge_requests`         | For pipelines created when a merge request is created or updated. Enables [merge request pipelines](../merge_request_pipelines/index.md), [merged results pipelines](../merge_request_pipelines/pipelines_for_merged_results/index.md), and [merge trains](../merge_request_pipelines/pipelines_for_merged_results/merge_trains/index.md). |
| `pipelines`              | For [multi-project pipelines](../multi_project_pipelines.md) created by [using the API with `CI_JOB_TOKEN`](../multi_project_pipelines.md#triggering-multi-project-pipelines-through-api), or the [`trigger`](#trigger) keyword. |
| `pushes`                 | For pipelines triggered by a `git push` event, including for branches and tags.                                                                                                                                                  |
| `schedules`              | For [scheduled pipelines](../pipelines/schedules.md).                                                                                                                                                                            |
| `tags`                   | When the Git reference for a pipeline is a tag.                                                                                                                                                                                  |
| `triggers`               | For pipelines created by using a [trigger token](../triggers/README.md#trigger-token).                                                                                                                                           |
| `web`                    | For pipelines created by using **Run pipeline** button in the GitLab UI, from the project's **CI/CD > Pipelines** section.                                                                                                       |

Scheduled pipelines run on specific branches, so jobs configured with `only: branches`
run on scheduled pipelines too. Add `except: schedules` to prevent jobs with `only: branches`
from running on scheduled pipelines.

In the example below, `job` runs only for refs that start with `issue-`,
whereas all branches are skipped:

```yaml
job:
  # use regexp
  only:
    - /^issue-.*$/
  # use special keyword
  except:
    - branches
```

Pattern matching is case-sensitive by default. Use `i` flag modifier, like
`/pattern/i` to make a pattern case-insensitive:

```yaml
job:
  # use regexp
  only:
    - /^issue-.*$/i
  # use special keyword
  except:
    - branches
```

In this example, `job` runs only for refs that are tagged, or if a build is
explicitly requested by an API trigger or a [Pipeline Schedule](../pipelines/schedules.md):

```yaml
job:
  # use special keywords
  only:
    - tags
    - triggers
    - schedules
```

The repository path can be used to have jobs executed only for the parent
repository and not forks:

```yaml
job:
  only:
    - branches@gitlab-org/gitlab
  except:
    - master@gitlab-org/gitlab
    - /^release/.*$/@gitlab-org/gitlab
```

The above example runs `job` for all branches on `gitlab-org/gitlab`,
except `master` and those with names prefixed with `release/`.

If a job does not have an `only` rule, `only: ['branches', 'tags']` is set by
default. If it does not have an `except` rule, it's empty.

For example,

```yaml
job:
  script: echo 'test'
```

is translated to:

```yaml
job:
  script: echo 'test'
  only: ['branches', 'tags']
```

#### Regular expressions

The `@` symbol denotes the beginning of a ref's repository path.
To match a ref name that contains the `@` character in a regular expression,
you must use the hex character code match `\x40`.

Only the tag or branch name can be matched by a regular expression.
The repository path, if given, is always matched literally.

To match the tag or branch name,
the entire ref name part of the pattern must be a regular expression surrounded by `/`.
For example, you can't use `issue-/.*/` to match all tag names or branch names
that begin with `issue-`, but you can use `/issue-.*/`.

Regular expression flags must be appended after the closing `/`.

TIP: **Tip:**
Use anchors `^` and `$` to avoid the regular expression
matching only a substring of the tag name or branch name.
For example, `/^issue-.*$/` is equivalent to `/^issue-/`,
while just `/issue/` would also match a branch called `severe-issues`.

#### Supported `only`/`except` regexp syntax

In GitLab 11.9.4, GitLab began internally converting the regexp used
in `only` and `except` keywords to [RE2](https://github.com/google/re2/wiki/Syntax).

[RE2](https://github.com/google/re2/wiki/Syntax) limits the set of available features
due to computational complexity, and some features, like negative lookaheads, became unavailable.
Only a subset of features provided by [Ruby Regexp](https://ruby-doc.org/core/Regexp.html)
are now supported.

From GitLab 11.9.7 to GitLab 12.0, GitLab provided a feature flag to
let you use unsafe regexp syntax. After migrating to safe syntax, you should disable
this feature flag again:

```ruby
Feature.enable(:allow_unsafe_ruby_regexp)
```

### `only`/`except` (advanced)

GitLab supports both simple and complex strategies, so it's possible to use an
array and a hash configuration scheme.

Four keys are available:

- `refs`
- `variables`
- `changes`
- `kubernetes`

If you use multiple keys under `only` or `except`, the keys are evaluated as a
single conjoined expression. That is:

- `only:` includes the job if **all** of the keys have at least one condition that matches.
- `except:` excludes the job if **any** of the keys have at least one condition that matches.

With `only`, individual keys are logically joined by an `AND`. A job is added to
the pipeline if the following is true:

- `(any listed refs are true) AND (any listed variables are true) AND (any listed changes are true) AND (any chosen Kubernetes status matches)`

In the example below, the `test` job is `only` created when **all** of the following are true:

- The pipeline has been [scheduled](../pipelines/schedules.md) **or** runs for `master`.
- The `variables` keyword matches.
- The `kubernetes` service is active on the project.

```yaml
test:
  script: npm run test
  only:
    refs:
      - master
      - schedules
    variables:
      - $CI_COMMIT_MESSAGE =~ /run-end-to-end-tests/
    kubernetes: active
```

With `except`, individual keys are logically joined by an `OR`. A job is **not**
added if the following is true:

- `(any listed refs are true) OR (any listed variables are true) OR (any listed changes are true) OR (a chosen Kubernetes status matches)`

In the example below, the `test` job is **not** created when **any** of the following are true:

- The pipeline runs for the `master` branch.
- There are changes to the `README.md` file in the root directory of the repository.

```yaml
test:
  script: npm run test
  except:
    refs:
      - master
    changes:
      - "README.md"
```

#### `only:refs`/`except:refs`

> `refs` policy introduced in GitLab 10.0.

The `refs` strategy can take the same values as the
[simplified only/except configuration](#onlyexcept-basic).

In the example below, the `deploy` job is created only when the
pipeline is [scheduled](../pipelines/schedules.md) or runs for the `master` branch:

```yaml
deploy:
  only:
    refs:
      - master
      - schedules
```

#### `only:kubernetes`/`except:kubernetes`

> `kubernetes` policy introduced in GitLab 10.0.

The `kubernetes` strategy accepts only the `active` keyword.

In the example below, the `deploy` job is created only when the
Kubernetes service is active in the project:

```yaml
deploy:
  only:
    kubernetes: active
```

#### `only:variables`/`except:variables`

> `variables` policy introduced in GitLab 10.7.

The `variables` keyword defines variable expressions.

These expressions determine whether or not a job should be created.

Examples of using variable expressions:

```yaml
deploy:
  script: cap staging deploy
  only:
    refs:
      - branches
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

Another use case is excluding jobs depending on a commit message:

```yaml
end-to-end:
  script: rake test:end-to-end
  except:
    variables:
      - $CI_COMMIT_MESSAGE =~ /skip-end-to-end-tests/
```

You can use [parentheses](../variables/README.md#parentheses) with `&&` and `||` to build more complicated variable expressions.
[Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/230938) in GitLab 13.3:

```yaml
job1:
  script:
    - echo This rule uses parentheses.
  only:
    variables:
      - ($CI_COMMIT_BRANCH == "master" || $CI_COMMIT_BRANCH == "develop") && $MY_VARIABLE
```

#### `only:changes`/`except:changes`

> `changes` policy [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/19232) in GitLab 11.4.

Using the `changes` keyword with `only` or `except` makes it possible to define if
a job should be created based on files modified by a Git push event.

Use the `only:changes` policy for pipelines triggered by the following
refs only:

- `branches`
- `external_pull_requests`
- `merge_requests` (see additional details about [using `only:changes` with pipelines for merge requests](#using-onlychanges-with-pipelines-for-merge-requests))

CAUTION: **Caution:**
In pipelines with [sources other than the three above](../variables/predefined_variables.md)
`changes` can't determine if a given file is new or old and always returns `true`.
You can configure jobs to use `only: changes` with other `only: refs` keywords. However,
those jobs ignore the changes and always run.

A basic example of using `only: changes`:

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

When you push commits to an existing branch,
the `docker build` job is created, but only if changes were made to any of the following:

- The `Dockerfile` file.
- Any of the files in the `docker/scripts/` directory.
- Any of the files and subdirectories in the `dockerfiles` directory.
- Any of the files with `rb`, `py`, `sh` extensions in the `more_scripts` directory.

CAUTION: **Warning:**
If you use `only:changes` with [only allow merge requests to be merged if the pipeline succeeds](../../user/project/merge_requests/merge_when_pipeline_succeeds.md#only-allow-merge-requests-to-be-merged-if-the-pipeline-succeeds),
you should [also use `only:merge_requests`](#using-onlychanges-with-pipelines-for-merge-requests). Otherwise it may not work as expected.

You can also use glob patterns to match multiple files in either the root directory
of the repository, or in _any_ directory in the repository. However, they must be wrapped
in double quotes or GitLab can't parse them. For example:

```yaml
test:
  script: npm run test
  only:
    refs:
      - branches
    changes:
      - "*.json"
      - "**/*.sql"
```

You can skip a job if a change is detected in any file with a
`.md` extension in the root directory of the repository:

```yaml
build:
  script: npm run build
  except:
    changes:
      - "*.md"
```

If you change multiple files, but only one file ends in `.md`,
the `build` job is still skipped. The job does not run for any of the files.

Read more about how to use this feature with:

- [New branches or tags *without* pipelines for merge requests](#using-onlychanges-without-pipelines-for-merge-requests).
- [Scheduled pipelines](#using-onlychanges-with-scheduled-pipelines).

##### Using `only:changes` with pipelines for merge requests

With [pipelines for merge requests](../merge_request_pipelines/index.md),
it's possible to define a job to be created based on files modified
in a merge request.

Use this keyword with `only: [merge_requests]` so GitLab can find the correct base
SHA of the source branch. File differences are correctly calculated from any further
commits, and all changes in the merge requests are properly tested in pipelines.

For example:

```yaml
docker build service one:
  script: docker build -t my-service-one-image:$CI_COMMIT_REF_SLUG .
  only:
    refs:
      - merge_requests
    changes:
      - Dockerfile
      - service-one/**/*
```

In this scenario, if a merge request changes
files in the `service-one` directory or the `Dockerfile`, GitLab creates
the `docker build service one` job.

For example:

```yaml
docker build service one:
  script: docker build -t my-service-one-image:$CI_COMMIT_REF_SLUG .
  only:
    changes:
      - Dockerfile
      - service-one/**/*
```

In the example above, the pipeline might fail because of changes to a file in `service-one/**/*`.

A later commit that doesn't have changes in `service-one/**/*`
but does have changes to the `Dockerfile` can pass. The job
only tests the changes to the `Dockerfile`.

GitLab checks the **most recent pipeline** that **passed**. If the merge request is mergeable,
it doesn't matter that an earlier pipeline failed because of a change that has not been corrected.

When you use this configuration, ensure that the most recent pipeline
properly corrects any failures from previous pipelines.

##### Using `only:changes` without pipelines for merge requests

Without [pipelines for merge requests](../merge_request_pipelines/index.md), pipelines
run on branches or tags that don't have an explicit association with a merge request.
In this case, a previous SHA is used to calculate the diff, which is equivalent to `git diff HEAD~`.
This can result in some unexpected behavior, including:

- When pushing a new branch or a new tag to GitLab, the policy always evaluates to true.
- When pushing a new commit, the changed files are calculated using the previous commit
  as the base SHA.

##### Using `only:changes` with scheduled pipelines

`only:changes` always evaluates as "true" in [Scheduled pipelines](../pipelines/schedules.md).
All files are considered to have "changed" when a scheduled pipeline
runs.

### `needs`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/47063) in GitLab 12.2.
> - In GitLab 12.3, maximum number of jobs in `needs` array raised from five to 50.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/30631) in GitLab 12.8, `needs: []` lets jobs start immediately.

Use the `needs:` keyword to execute jobs out-of-order. Relationships between jobs
that use `needs` can be visualized as a [directed acyclic graph](../directed_acyclic_graph/index.md).

You can ignore stage ordering and run some jobs without waiting for others to complete.
Jobs in multiple stages can run concurrently.

Let's consider the following example:

```yaml
linux:build:
  stage: build

mac:build:
  stage: build

lint:
  stage: test
  needs: []

linux:rspec:
  stage: test
  needs: ["linux:build"]

linux:rubocop:
  stage: test
  needs: ["linux:build"]

mac:rspec:
  stage: test
  needs: ["mac:build"]

mac:rubocop:
  stage: test
  needs: ["mac:build"]

production:
  stage: deploy
```

This example creates four paths of execution:

- Linter: the `lint` job runs immediately without waiting for the `build` stage to complete because it has no needs (`needs: []`).

- Linux path: the `linux:rspec` and `linux:rubocop` jobs runs as soon
  as the `linux:build` job finishes without waiting for `mac:build` to finish.

- macOS path: the `mac:rspec` and `mac:rubocop` jobs runs as soon
  as the `mac:build` job finishes, without waiting for `linux:build` to finish.

- The `production` job runs as soon as all previous jobs
  finish; in this case: `linux:build`, `linux:rspec`, `linux:rubocop`,
  `mac:build`, `mac:rspec`, `mac:rubocop`.

#### Requirements and limitations

- If `needs:` is set to point to a job that is not instantiated
  because of `only/except` rules or otherwise does not exist, the
  pipeline is not created and a YAML error is shown.
- The maximum number of jobs that a single job can need in the `needs:` array is limited:
  - For GitLab.com, the limit is 50. For more information, see our
    [infrastructure issue](https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/7541).
  - For self-managed instances, the limit is: 50. This limit [can be changed](#changing-the-needs-job-limit).
- If `needs:` refers to a job that is marked as `parallel:`.
  the current job depends on all parallel jobs being created.
- `needs:` is similar to `dependencies:` in that it must use jobs from prior stages,
  meaning it's impossible to create circular dependencies. Depending on jobs in the
  current stage is not possible either, but support [is planned](https://gitlab.com/gitlab-org/gitlab/-/issues/30632).
- Related to the above, stages must be explicitly defined for all jobs
  that have the keyword `needs:` or are referred to by one.

##### Changing the `needs:` job limit **(CORE ONLY)**

The maximum number of jobs that can be defined in `needs:` defaults to 50.

A GitLab administrator with [access to the GitLab Rails console](../../administration/feature_flags.md)
can choose a custom limit. For example, to set the limit to 100:

```ruby
Plan.default.actual_limits.update!(ci_needs_size_limit: 100)
```

To disable directed acyclic graphs (DAG), set the limit to `0`.

#### Artifact downloads with `needs`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14311) in GitLab v12.6.

When using `needs`, artifact downloads are controlled with `artifacts: true` (default) or `artifacts: false`.

In GitLab 12.6 and later, you can't combine the [`dependencies`](#dependencies) keyword
with `needs` to control artifact downloads in jobs. `dependencies` is still valid
in jobs that do not use `needs`.

In the example below, the `rspec` job downloads the `build_job` artifacts, while the
`rubocop` job doesn't:

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

Additionally, in the three syntax examples below, the `rspec` job downloads the artifacts
from all three `build_jobs`. `artifacts` is true for `build_job_1` and
**defaults** to true for both `build_job_2` and `build_job_3`.

```yaml
rspec:
  needs:
    - job: build_job_1
      artifacts: true
    - job: build_job_2
    - build_job_3
```

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
      ref: master
      artifacts: true
```

`build_job` downloads the artifacts from the latest successful `build-1` job
on the `master` branch in the `group/project-name` project. If the project is in the
same group or namespace, you can omit them from the `project:` key. For example,
`project: group/project-name` or `project: project-name`.

The user running the pipeline must have at least `reporter` access to the group or project, or the group/project must have public visibility.

##### Artifact downloads between pipelines in the same project

Use `needs` to download artifacts from different pipelines in the current project.
Set the `project` keyword as the current project's name, and specify a ref.

In this example, `build_job` downloads the artifacts for the latest successful
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

Environment variables support for `project:`, `job:`, and `ref` was [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/202093)
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
      ref: $CI_COMMIT_BRANCH
      artifacts: true
```

Downloading artifacts from jobs that are run in [`parallel:`](#parallel) is not supported.

### `tags`

Use `tags` to select a specific runner from the list of all runners that are
available for the project.

When you register a runner, you can specify the runner's tags, for
example `ruby`, `postgres`, `development`.

In this example, the job is run by a runner that
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
suite.
The default value is `false`, except for [manual](#whenmanual) jobs using the
`when: manual` syntax, unless using [`rules:`](#rules) syntax, where all jobs
default to false, *including* `when: manual` jobs.

When `allow_failure` is set to `true` and the job fails, the job shows an orange warning in the UI.
However, the logical flow of the pipeline considers the job a
success/passed, and is not blocked.

Assuming all other jobs are successful, the job's stage and its pipeline
show the same orange warning. However, the associated commit is marked as
"passed", without warnings.

In the example below, `job1` and `job2` run in parallel, but if `job1`
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

### `when`

`when` is used to implement jobs that are run in case of failure or despite the
failure.

`when` can be set to one of the following values:

1. `on_success` (default) - Execute job only when all jobs in earlier stages succeed,
    or are considered successful because they have `allow_failure: true`.
1. `on_failure` - Execute job only when at least one job in an earlier stage fails.
1. `always` - Execute job regardless of the status of jobs in earlier stages.
1. `manual` - Execute job [manually](#whenmanual).
1. `delayed` - [Delay the execution of a job](#whendelayed) for a specified duration.
    Added in GitLab 11.14.
1. `never`:
   - With [`rules`](#rules), don't execute job.
   - With [`workflow:rules`](#workflowrules), don't run pipeline.

For example:

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

The above script:

1. Executes `cleanup_build_job` only when `build_job` fails.
1. Always executes `cleanup_job` as the last step in pipeline regardless of
   success or failure.
1. Executes `deploy_job` when you run it manually in the GitLab UI.

#### `when:manual`

A manual job is a type of job that is not executed automatically and must be explicitly
started by a user. You might want to use manual jobs for things like deploying to production.

To make a job manual, add `when: manual` to its configuration.

Manual jobs can be started from the pipeline, job, [environment](../environments/index.md#configuring-manual-deployments),
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
It is deployed behind the `:ci_manual_bridges` [feature flag](../../user/feature_flags.md), which is **enabled by default**.
[GitLab administrators with access to the Rails console](../../administration/feature_flags.md)
can opt to disable it.

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
     only:
       - master
   ```

1. In the [protected environments settings](../environments/protected_environments.md#protecting-environments),
   select the environment (`production` in the example above) and add the users, roles or groups
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

You can set the period with `start_in` key. The value of `start_in` key is an elapsed time in seconds, unless a unit is
provided. `start_in` key must be less than or equal to one week. Examples of valid values include:

- `'5'`
- `5 seconds`
- `30 minutes`
- `1 day`
- `1 week`

When there is a delayed job in a stage, the pipeline doesn't progress until the delayed job has finished.
This keyword can also be used for inserting delays between different stages.

The timer of a delayed job starts immediately after the previous stage has completed.
Similar to other types of jobs, a delayed job's timer doesn't start unless the previous stage passed.

The following example creates a job named `timed rollout 10%` that is executed 30 minutes after the previous stage has completed:

```yaml
timed rollout 10%:
  stage: deploy
  script: echo 'Rolling out 10% ...'
  when: delayed
  start_in: 30 minutes
```

You can stop the active timer of a delayed job by clicking the **{time-out}** (**Unschedule**) button.
This job can no longer be scheduled to run automatically. You can, however, execute the job manually.

To start a delayed job immediately, click the **Play** button.
Soon GitLab Runner picks up and starts the job.

### `environment`

Use `environment` to define the [environment](../environments/index.md) that a job deploys to.
If `environment` is specified and no environment under that name exists, a new
one is created automatically.

In its simplest form, the `environment` keyword can be defined like:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment: production
```

In the above example, the `deploy to production` job is marked as doing a
deployment to the `production` environment.

#### `environment:name`

The `environment: name` keyword can use any of the defined CI variables,
including predefined, secure, or `.gitlab-ci.yml` [`variables`](#variables).

You can't use variables defined in a `script` section.

The `environment` name can contain:

- letters
- digits
- spaces
- `-`
- `_`
- `/`
- `$`
- `{`
- `}`

Common names are `qa`, `staging`, and `production`, but you can use whatever
name works with your workflow.

Instead of defining the name of the environment right after the `environment`
keyword, it's also possible to define it as a separate value. For that, use
the `name` keyword under `environment`:

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
```

#### `environment:url`

The `url` keyword can use any of the defined CI variables,
including predefined, secure, or `.gitlab-ci.yml` [`variables`](#variables).

You can't use variables defined in a `script` section.

This optional value exposes buttons that take you to the defined URL

In this example, if the job finishes successfully, it creates buttons
in the merge requests and in the environments/deployments pages that point
to `https://prod.example.com`.

```yaml
deploy to production:
  stage: deploy
  script: git push production HEAD:master
  environment:
    name: production
    url: https://prod.example.com
```

#### `environment:on_stop`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/22191) in GitLab 8.13.
> - Starting with GitLab 8.14, when you have an environment that has a stop action
>   defined, GitLab automatically triggers a stop action when the associated
>   branch is deleted.

Closing (stopping) environments can be achieved with the `on_stop` keyword
defined under `environment`. It declares a different job that runs to close the
environment.

Read the `environment:action` section for an example.

#### `environment:action`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/22191) in GitLab 8.13.

The `action` keyword can be used to specify jobs that prepare, start, or stop environments.

| **Value** | **Description**                                                                                                                                               |
|-----------|---------------------------------------------------------------------------------------------------------------------------------------------------------------|
| start     | Default value. Indicates that job starts the environment. The deployment is created after the job starts.                                                          |
| prepare   | Indicates that job is only preparing the environment. Does not affect deployments. [Read more about environments](../environments/index.md#prepare-an-environment) |
| stop      | Indicates that job stops deployment. See the example below.                                                                                                   |

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
GitLab's user interface to run.

Also in the example, `GIT_STRATEGY` is set to `none`. If the
`stop_review_app` job is [automatically triggered](../environments/index.md#automatically-stopping-an-environment),
the runner won’t try to check out the code after the branch is deleted.

The example also overwrites global variables. If your `stop` `environment` job depends
on global variables, use [anchor variables](#yaml-anchors-for-variables) when you set the `GIT_STRATEGY`
to change the job without overriding the global variables.

The `stop_review_app` job is **required** to have the following keywords defined:

- `when` - [reference](#when)
- `environment:name`
- `environment:action`

Additionally, both jobs should have matching [`rules`](../yaml/README.md#onlyexcept-basic)
or [`only/except`](../yaml/README.md#onlyexcept-basic) configuration.

In the example above, if the configuration is not identical:

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
[the environments auto-stop documentation](../environments/index.md#environments-auto-stop)

#### `environment:kubernetes`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/27630) in GitLab 12.6.

The `kubernetes` block is used to configure deployments to a
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
[Available settings for `kubernetes`](../environments/index.md#configuring-kubernetes-deployments).

NOTE: **Note:**
Kubernetes configuration is not supported for Kubernetes clusters
that are [managed by GitLab](../../user/project/clusters/index.md#gitlab-managed-clusters).
To follow progress on support for GitLab-managed clusters, see the
[relevant issue](https://gitlab.com/gitlab-org/gitlab/-/issues/38054).

#### Dynamic environments

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/21971) in GitLab 8.12 and GitLab Runner 1.6.
> - The `$CI_ENVIRONMENT_SLUG` was [introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/22864) in GitLab 8.15.

Use CI/CD [variables](../variables/README.md) to dynamically name environments.

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
is an [environment variable](../variables/README.md) set by the runner. The
`$CI_ENVIRONMENT_SLUG` variable is based on the environment name, but suitable
for inclusion in URLs. If the `deploy as review app` job runs in a branch named
`pow`, this environment would be accessible with a URL like `https://review-pow.example.com/`.

The common use case is to create dynamic environments for branches and use them
as Review Apps. You can see an example that uses Review Apps at
<https://gitlab.com/gitlab-examples/review-apps-nginx/>.

### `cache`

`cache` is used to specify a list of files and directories that should be
cached between jobs. You can only use paths that are in the local working copy.

If `cache` is defined outside the scope of jobs, it means it's set
globally and all jobs use that definition.

Caching is shared between pipelines and jobs. Caches are restored before [artifacts](#artifacts).

Read how caching works and find out some good practices in the
[caching dependencies documentation](../caching/index.md).

#### `cache:paths`

Use the `paths` directive to choose which files or directories to cache. Paths
are relative to the project directory (`$CI_PROJECT_DIR`) and can't directly link outside it.
Wildcards can be used that follow the [glob](https://en.wikipedia.org/wiki/Glob_(programming))
patterns and:

- In [GitLab Runner 13.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620) and later,
[`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match).
- In GitLab Runner 12.10 and earlier,
[`filepath.Match`](https://pkg.go.dev/path/filepath/#Match).

Cache all files in `binaries` that end in `.apk` and the `.config` file:

```yaml
rspec:
  script: test
  cache:
    paths:
      - binaries/*.apk
      - .config
```

Locally defined cache overrides globally defined options. The following `rspec`
job caches only `binaries/`:

```yaml
cache:
  paths:
    - my/files

rspec:
  script: test
  cache:
    key: rspec
    paths:
      - binaries/
```

The cache is shared between jobs, so if you're using different
paths for different jobs, you should also set a different `cache:key`.
Otherwise cache content can be overwritten.

#### `cache:key`

The `key` keyword defines the affinity of caching between jobs.
You can have a single cache for all jobs, cache per-job, cache per-branch,
or any other way that fits your workflow. You can fine tune caching,
including caching data between different jobs or even different branches.

The `cache:key` variable can use any of the
[predefined variables](../variables/README.md). The default key, if not
set, is just literal `default`, which means everything is shared between
pipelines and jobs by default.

For example, to enable per-branch caching:

```yaml
cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - binaries/
```

If you use **Windows Batch** to run your shell scripts you need to replace
`$` with `%`:

```yaml
cache:
  key: "%CI_COMMIT_REF_SLUG%"
  paths:
    - binaries/
```

The `cache:key` variable can't contain the `/` character, or the equivalent
URI-encoded `%2F`. A value made only of dots (`.`, `%2E`) is also forbidden.

You can specify a [fallback cache key](#fallback-cache-key) to use if the specified `cache:key` is not found.

#### Fallback cache key

> [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/merge_requests/1534) in GitLab Runner 13.4.

You can use the `$CI_COMMIT_REF_SLUG` [variable](#variables) to specify your [`cache:key`](#cachekey).
For example, if your `$CI_COMMIT_REF_SLUG` is `test` you can set a job
to download cache that's tagged with `test`.

If a cache with this tag is not found, you can use `CACHE_FALLBACK_KEY` to
specify a cache to use when none exists.

For example:

```yaml
variables:
  CACHE_FALLBACK_KEY: fallback-key

cache:
  key: "$CI_COMMIT_REF_SLUG"
  paths:
    - binaries/
```

In this example, if the `$CI_COMMIT_REF_SLUG` is not found, the job uses the key defined
by the `CACHE_FALLBACK_KEY` variable.

##### `cache:key:files`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18986) in GitLab v12.5.

The `cache:key:files` keyword extends the `cache:key` functionality by making it easier
to reuse some caches, and rebuild them less often, which speeds up subsequent pipeline
runs.

When you include `cache:key:files`, you must also list the project files that are used to generate the key, up to a maximum of two files.
The cache `key` is a SHA checksum computed from the most recent commits (up to two, if two files are listed)
that changed the given files. If neither file was changed in any commits,
the fallback key is `default`.

```yaml
cache:
  key:
    files:
      - Gemfile.lock
      - package.json
  paths:
    - vendor/ruby
    - node_modules
```

In this example we're creating a cache for Ruby and Node.js dependencies that
is tied to current versions of the `Gemfile.lock` and `package.json` files. Whenever one of
these files changes, a new cache key is computed and a new cache is created. Any future
job runs that use the same `Gemfile.lock` and `package.json` with `cache:key:files`
use the new cache, instead of rebuilding the dependencies.

##### `cache:key:prefix`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/18986) in GitLab v12.5.

When you want to combine a prefix with the SHA computed for `cache:key:files`,
use the `prefix` keyword with `key:files`.
For example, if you add a `prefix` of `test`, the resulting key is: `test-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5`.
If neither file was changed in any commits, the prefix is added to `default`, so the
key in the example would be `test-default`.

Like `cache:key`, `prefix` can use any of the [predefined variables](../variables/README.md),
but cannot include:

- the `/` character (or the equivalent URI-encoded `%2F`)
- a value made only of `.` (or the equivalent URI-encoded `%2E`)

```yaml
cache:
  key:
    files:
      - Gemfile.lock
    prefix: ${CI_JOB_NAME}
  paths:
    - vendor/ruby

rspec:
  script:
    - bundle exec rspec
```

For example, adding a `prefix` of `$CI_JOB_NAME`
causes the key to look like: `rspec-feef9576d21ee9b6a32e30c5c79d0a0ceb68d1e5` and
the job cache is shared across different branches. If a branch changes
`Gemfile.lock`, that branch has a new SHA checksum for `cache:key:files`. A new cache key
is generated, and a new cache is created for that key.
If `Gemfile.lock` is not found, the prefix is added to
`default`, so the key in the example would be `rspec-default`.

#### `cache:untracked`

Set `untracked: true` to cache all files that are untracked in your Git
repository:

```yaml
rspec:
  script: test
  cache:
    untracked: true
```

Cache all Git untracked files and files in `binaries`:

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

`cache:when` defines when to save the cache, based on the status of the job. You can
set `cache:when` to:

- `on_success` (default): Save the cache only when the job succeeds.
- `on_failure`: Save the cache only when the job fails.
- `always`: Always save the cache.

For example, to store a cache whether or not the job fails or succeeds:

```yaml
rspec:
  script: rspec
  cache:
    paths:
      - rspec/
    when: 'always'
```

#### `cache:policy`

The default behavior of a caching job is to download the files at the start of
execution, and to re-upload them at the end. Any changes made by the
job are persisted for future runs. This behavior is known as the `pull-push` cache
policy.

If you know the job does not alter the cached files, you can skip the upload step
by setting `policy: pull` in the job specification. You can add an ordinary cache
job at an earlier stage to ensure the cache is updated from time to time:

```yaml
stages:
  - setup
  - test

prepare:
  stage: setup
  cache:
    key: gems
    paths:
      - vendor/bundle
  script:
    - bundle install --deployment

rspec:
  stage: test
  cache:
    key: gems
    paths:
      - vendor/bundle
    policy: pull
  script:
    - bundle exec rspec ...
```

The `pull` policy speeds up job execution and reduces load on the cache server. It
can be used when you have many jobs that use caches executing in parallel.

If you have a job that unconditionally recreates the cache without
referring to its previous contents, you can skip the download step.
To do so, add `policy: push` to the job.

### `artifacts`

`artifacts` is used to specify a list of files and directories that are
attached to the job when it [succeeds, fails, or always](#artifactswhen).

The artifacts are sent to GitLab after the job finishes. They are
available for download in the GitLab UI if the size is not
larger than the [maximum artifact size](../../user/gitlab_com/index.md#gitlab-cicd).

Job artifacts are only collected for successful jobs by default, and
artifacts are restored after [caches](#cache).

[Not all executors can use caches](https://docs.gitlab.com/runner/executors/#compatibility-chart).

[Read more about artifacts](../pipelines/job_artifacts.md).

#### `artifacts:paths`

Paths are relative to the project directory (`$CI_PROJECT_DIR`) and can't directly
link outside it. Wildcards can be used that follow the [glob](https://en.wikipedia.org/wiki/Glob_(programming))
patterns and:

- In [GitLab Runner 13.0](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/2620) and later,
[`doublestar.Glob`](https://pkg.go.dev/github.com/bmatcuk/doublestar@v1.2.2?tab=doc#Match).
- In GitLab Runner 12.10 and earlier,
[`filepath.Match`](https://pkg.go.dev/path/filepath/#Match).

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
  except:
    - tags

release-job:
  script:
    - mvn package -U
  artifacts:
    paths:
      - target/*.war
  only:
    - tags
```

You can use wildcards for directories too. For example, if you want to get all the files inside the directories that end with `xyz`:

```yaml
job:
  artifacts:
    paths:
      - path/*xyz/*
```

#### `artifacts:exclude`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15122) in GitLab 13.1
> - Requires GitLab Runner 13.1

`exclude` makes it possible to prevent files from being added to an artifacts
archive.

Similar to [`artifacts:paths`](#artifactspaths), `exclude` paths are relative
to the project directory. Wildcards can be used that follow the
[glob](https://en.wikipedia.org/wiki/Glob_(programming)) patterns and
[`filepath.Match`](https://golang.org/pkg/path/filepath/#Match).

For example, to store all files in `binaries/`, but not `*.o` files located in
subdirectories of `binaries/`:

```yaml
artifacts:
  paths:
    - binaries/
  exclude:
    - binaries/**/*.o
```

Files matched by [`artifacts:untracked`](#artifactsuntracked) can be excluded using
`artifacts:exclude` too.

#### `artifacts:expose_as`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15018) in GitLab 12.5.

The `expose_as` keyword can be used to expose [job artifacts](../pipelines/job_artifacts.md)
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
that points to `file1.txt`.

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
- If a directory is specified, the link is to the job [artifacts browser](../pipelines/job_artifacts.md#browsing-artifacts) if there is more than
  one file in the directory.
- For exposed single file artifacts with `.html`, `.htm`, `.txt`, `.json`, `.xml`,
  and `.log` extensions, if [GitLab Pages](../../administration/pages/index.md) is:
  - Enabled, GitLab automatically renders the artifact.
  - Not enabled, the file is displayed in the artifacts browser.

#### `artifacts:name`

Use the `name` directive to define the name of the created artifacts
archive. You can specify a unique name for every archive. The `artifacts:name`
variable can make use of any of the [predefined variables](../variables/README.md).
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

#### `artifacts:untracked`

`artifacts:untracked` is used to add all Git untracked files as artifacts (along
to the paths defined in `artifacts:paths`). `artifacts:untracked` ignores configuration
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

`artifacts:when` is used to upload artifacts on job failure or despite the
failure.

`artifacts:when` can be set to one of the following values:

1. `on_success` (default): Upload artifacts only when the job succeeds.
1. `on_failure`: Upload artifacts only when the job fails.
1. `always`: Always upload artifacts.

For example, to upload artifacts only when a job fails:

```yaml
job:
  artifacts:
    when: on_failure
```

#### `artifacts:expire_in`

Use `expire_in` to specify how long artifacts are active before they
expire and are deleted.

The expiration time period begins when the artifact is uploaded and
stored on GitLab. If the expiry time is not defined, it defaults to the
[instance wide setting](../../user/admin_area/settings/continuous_integration.md#default-artifacts-expiration)
(30 days by default).

To override the expiration date and protect artifacts from being automatically deleted:

- Use the **Keep** button on the job page.
- Set the value of `expire_in` to `never`. [Available](https://gitlab.com/gitlab-org/gitlab/-/issues/22761)
  in GitLab 13.3 and later.

After their expiry, artifacts are deleted hourly by default (via a cron job),
and are not accessible anymore.

The value of `expire_in` is an elapsed time in seconds, unless a unit is
provided. Examples of valid values:

- `'42'`
- `42 seconds`
- `3 mins 4 sec`
- `2 hrs 20 min`
- `2h20min`
- `6 mos 1 day`
- `47 yrs 6 mos and 4d`
- `3 weeks and 2 days`
- `never`

To expire artifacts 1 week after being uploaded:

```yaml
job:
  artifacts:
    expire_in: 1 week
```

The latest artifacts for refs are locked against deletion, and kept regardless of
the expiry time. [Introduced in](https://gitlab.com/gitlab-org/gitlab/-/issues/16267)
GitLab 13.0 behind a disabled feature flag, and [made the default behavior](https://gitlab.com/gitlab-org/gitlab/-/issues/229936)
in GitLab 13.4.

#### `artifacts:reports`

The [`artifacts:reports` keyword](../pipelines/job_artifacts.md#artifactsreports)
is used for collecting test reports, code quality reports, and security reports from jobs.
It also exposes these reports in GitLab's UI (merge requests, pipeline views, and security dashboards).

These are the available report types:

| Keyword                                                                                                                     | Description                                                                      |
|-----------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------|
| [`artifacts:reports:cobertura`](../pipelines/job_artifacts.md#artifactsreportscobertura)                                    | The `cobertura` report collects Cobertura coverage XML files.                    |
| [`artifacts:reports:codequality`](../pipelines/job_artifacts.md#artifactsreportscodequality)                                | The `codequality` report collects CodeQuality issues.                            |
| [`artifacts:reports:container_scanning`](../pipelines/job_artifacts.md#artifactsreportscontainer_scanning) **(ULTIMATE)**   | The `container_scanning` report collects Container Scanning vulnerabilities.     |
| [`artifacts:reports:dast`](../pipelines/job_artifacts.md#artifactsreportsdast) **(ULTIMATE)**                               | The `dast` report collects Dynamic Application Security Testing vulnerabilities. |
| [`artifacts:reports:dependency_scanning`](../pipelines/job_artifacts.md#artifactsreportsdependency_scanning) **(ULTIMATE)** | The `dependency_scanning` report collects Dependency Scanning vulnerabilities.   |
| [`artifacts:reports:dotenv`](../pipelines/job_artifacts.md#artifactsreportsdotenv)                                          | The `dotenv` report collects a set of environment variables.                     |
| [`artifacts:reports:junit`](../pipelines/job_artifacts.md#artifactsreportsjunit)                                            | The `junit` report collects JUnit XML files.                                     |
| [`artifacts:reports:license_management`](../pipelines/job_artifacts.md#artifactsreportslicense_management) **(ULTIMATE)**   | The `license_management` report collects Licenses (*removed from GitLab 13.0*).  |
| [`artifacts:reports:license_scanning`](../pipelines/job_artifacts.md#artifactsreportslicense_scanning) **(ULTIMATE)**       | The `license_scanning` report collects Licenses.                                 |
| [`artifacts:reports:load_performance`](../pipelines/job_artifacts.md#artifactsreportsload_performance) **(PREMIUM)**        | The `load_performance` report collects load performance metrics.                 |
| [`artifacts:reports:metrics`](../pipelines/job_artifacts.md#artifactsreportsmetrics) **(PREMIUM)**                          | The `metrics` report collects Metrics.                                           |
| [`artifacts:reports:performance`](../pipelines/job_artifacts.md#artifactsreportsperformance) **(PREMIUM)**                  | The `performance` report collects Browser Performance metrics.                   |
| [`artifacts:reports:sast`](../pipelines/job_artifacts.md#artifactsreportssast) **(ULTIMATE)**                               | The `sast` report collects Static Application Security Testing vulnerabilities.  |
| [`artifacts:reports:terraform`](../pipelines/job_artifacts.md#artifactsreportsterraform)                                    | The `terraform` report collects Terraform `tfplan.json` files.                   |

#### `dependencies`

By default, all [`artifacts`](#artifacts) from previous [stages](#stages)
are passed to each job. However, you can use the `dependencies` keyword to
define a limited list of jobs to fetch artifacts from. You can also set a job to download no artifacts at all.

To use this feature, define `dependencies` in context of the job and pass
a list of all previous jobs the artifacts should be downloaded from.

You can define jobs from stages that were executed before the current one.
An error occurs if you define jobs from the current or an upcoming stage.

To prevent a job from downloading artifacts, define an empty array.

When you use `dependencies`, the status of the previous job is not considered.
If a job fails or it's a manual job that was not run, no error occurs.

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

If the artifacts of the job that is set as a dependency have been
[expired](#artifactsexpire_in) or
[erased](../pipelines/job_artifacts.md#erasing-artifacts), then
the dependent job fails.

You can ask your administrator to
[flip this switch](../../administration/job_artifacts.md#validation-for-dependencies)
and bring back the old behavior.

### `coverage`

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/20428) in GitLab 8.17.

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

### `retry`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/3442) in GitLab 9.5.
> - [Behavior expanded](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/3515) in GitLab 11.5 to control which failures to retry on.

Use `retry` to configure how many times a job is retried in
case of a failure.

When a job fails, the job is processed again,
until the limit specified by the `retry` keyword is reached.

If `retry` is set to `2`, and a job succeeds in a second run (first retry), it is not retried.
The `retry` value must be a positive integer, from `0` to `2`
(two retries maximum, three runs in total).

This example retries all failure cases:

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
- `runner_system_failure`: Retry if there was a runner system failure (for example, job setup failed).
- `missing_dependency_failure`: Retry if a dependency was missing.
- `runner_unsupported`: Retry if the runner was unsupported.
- `stale_schedule`: Retry if a delayed job could not be executed.
- `job_execution_timeout`: Retry if the script exceeded the maximum execution time set for the job.
- `archived_failure`: Retry if the job is archived and can't be run.
- `unmet_prerequisites`: Retry if the job failed to complete prerequisite tasks.
- `scheduler_failure`: Retry if the scheduler failed to assign the job to a runner.
- `data_integrity_failure`: Retry if there was a structural integrity problem detected.

You can specify the number of [retry attempts for certain stages of job execution](../runners/README.md#job-stages-attempts) using variables.

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
[project-level timeout](../pipelines/settings.md#timeout) but can't
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
[environment variable](../variables/README.md#predefined-environment-variables) set.

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

CAUTION: **Caution:**
Test Boosters reports usage statistics to the author.

You can then navigate to the **Jobs** tab of a new pipeline build and see your RSpec
job split into three separate jobs.

#### Parallel `matrix` jobs

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15356) in GitLab 13.3.

Use `matrix:` to configure different variables for jobs that are running in parallel.
There can be from 2 to 50 jobs.

Jobs can only run in parallel if there are multiple runners, or a single runner is
[configured to run multiple jobs concurrently](#using-your-own-runners).

[In GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/26362) and later,
you can have one-dimensional matrices with a single job.

Every job gets the same `CI_NODE_TOTAL` [environment variable](../variables/README.md#predefined-environment-variables) value, and a unique `CI_NODE_INDEX` value.

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

This example generates 10 parallel `deploystacks` jobs, each with different values
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

### `trigger`

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/8997) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.8.
> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/199224) to GitLab Core in 12.8.

Use `trigger` to define a downstream pipeline trigger. When GitLab starts a job created
with a `trigger` definition, a downstream pipeline is created.

Jobs with `trigger` can only use a [limited set of keywords](../multi_project_pipelines.md#limitations).
For example, you can't run commands with [`script`](#script), [`before_script`](#before_script),
or [`after_script`](#after_script).

You can use this keyword to create two different types of downstream pipelines:

- [Multi-project pipelines](../multi_project_pipelines.md#creating-multi-project-pipelines-from-gitlab-ciyml)
- [Child pipelines](../parent_child_pipelines.md)

[In GitLab 13.2](https://gitlab.com/gitlab-org/gitlab/-/issues/197140/) and later, you can
view which job triggered a downstream pipeline. In the [pipeline graph](../pipelines/index.md#visualize-pipelines),
hover over the downstream pipeline job.

In [GitLab 13.5](https://gitlab.com/gitlab-org/gitlab/-/issues/201938) and later, you
can use [`when:manual`](#whenmanual) in the same job as `trigger`. In GitLab 13.4 and
earlier, using them together causes the error `jobs:#{job-name} when should be on_success, on_failure or always`.
It is deployed behind the `:ci_manual_bridges` [feature flag](../../user/feature_flags.md), which is **enabled by default**.
[GitLab administrators with access to the Rails console](../../administration/feature_flags.md)
can opt to disable it.

#### Simple `trigger` syntax for multi-project pipelines

The simplest way to configure a downstream trigger is to use `trigger` keyword
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

To create a [child pipeline](../parent_child_pipelines.md), specify the path to the
YAML file containing the CI config of the child pipeline:

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
```

Similar to [multi-project pipelines](../multi_project_pipelines.md#mirroring-status-from-triggered-pipeline),
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

You can also trigger a child pipeline from a [dynamically generated configuration file](../parent_child_pipelines.md#dynamic-child-pipelines):

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
        ref: 'master'
        file: '/path/to/child-pipeline.yml'
```

#### Linking pipelines with `trigger:strategy`

By default, the `trigger` job completes with the `success` status
as soon as the downstream pipeline is created.

To force the `trigger` job to wait for the downstream (multi-project or child) pipeline to complete, use
`strategy: depend`. This setting makes the trigger job wait with a "running" status until the triggered
pipeline completes. At that point, the `trigger` job completes and displays the same status as
the downstream job.

```yaml
trigger_job:
  trigger:
    include: path/to/child-pipeline.yml
    strategy: depend
```

This setting can help keep your pipeline execution linear. In the example above, jobs from
subsequent stages wait for the triggered pipeline to successfully complete before
starting, which reduces parallelization.

#### Trigger a pipeline by API call

To force a rebuild of a specific branch, tag, or commit, you can use an API call
with a trigger token.

The trigger token is different than the [`trigger`](#trigger) keyword.

[Read more in the triggers documentation.](../triggers/README.md)

### `interruptible`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/32022) in GitLab 12.3.

`interruptible` is used to indicate that a job should be canceled if made redundant by a newer pipeline run. Defaults to `false`.
This value is used only if the [automatic cancellation of redundant pipelines feature](../pipelines/settings.md#auto-cancel-pending-pipelines)
is enabled.

When enabled, a pipeline on the same branch is canceled when:

- It's made redundant by a newer pipeline run.
- Either all jobs are set as interruptible, or any uninterruptible jobs haven't started.

Set jobs as interruptible that can be safely canceled once started (for instance, a build job).

Pending jobs are always considered interruptible.

For example:

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

In the example above, a new pipeline run causes an existing running pipeline to be:

- Canceled, if only `step-1` is running or pending.
- Not canceled, once `step-2` starts running.

When an uninterruptible job is running, the pipeline can never be canceled, regardless of the final job's state.

### `resource_group`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/15536) in GitLab 12.7.

Sometimes running multiple jobs or pipelines at the same time in an environment
can lead to errors during the deployment.

To avoid these errors, the `resource_group` attribute can be used to ensure that
the runner doesn't run certain jobs simultaneously. Resource groups behave similar
to semaphores in other programming languages.

When the `resource_group` key is defined for a job in `.gitlab-ci.yml`,
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

### `release`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/merge_requests/19298) in GitLab 13.2.

`release` indicates that the job creates a [Release](../../user/project/releases/index.md).

These methods are supported:

- [`tag_name`](#releasetag_name)
- [`description`](#releasedescription)
- [`name`](#releasename) (optional)
- [`ref`](#releaseref) (optional)
- [`milestones`](#releasemilestones) (optional)
- [`released_at`](#releasereleased_at) (optional)

The Release is created only if the job processes without error. If the Rails API
returns an error during Release creation, the `release` job fails.

#### `release-cli` Docker image

The Docker image to use for the `release-cli` must be specified, using the following directive:

```yaml
image: registry.gitlab.com/gitlab-org/release-cli:latest
```

#### Script

All jobs except [trigger](#trigger) jobs must have the `script` keyword. A `release`
job can use the output from script commands, but a placeholder script can be used if
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

The `tag_name` must be specified. It can refer to an existing Git tag or can be specified by the user.

When the specified tag doesn't exist in the repository, a new tag is created from the associated SHA of the pipeline.

For example, when creating a Release from a Git tag:

```yaml
job:
  release:
    tag_name: $CI_COMMIT_TAG
    description: 'Release description'
```

It is also possible to create any unique tag, in which case `only: tags` is not mandatory.
A semantic versioning example:

```yaml
job:
  release:
    tag_name: ${MAJOR}_${MINOR}_${REVISION}
    description: 'Release description'
```

- The Release is created only if the job's main script succeeds.
- If the Release already exists, it is not updated and the job with the `release` keyword fails.
- The `release` section executes after the `script` tag and before the `after_script`.

#### `release:name`

The Release name. If omitted, it is populated with the value of `release: tag_name`.

#### `release:description`

Specifies the longer description of the Release.

#### `release:ref`

If the `release: tag_name` doesn’t exist yet, the release is created from `ref`.
`ref` can be a commit SHA, another tag name, or a branch name.

#### `release:milestones`

The title of each milestone the release is associated with.

#### `release:released_at`

The date and time when the release is ready. Defaults to the current date and time if not
defined. Should be enclosed in quotes and expressed in ISO 8601 format.

```json
released_at: '2021-03-15T08:00:00Z'
```

#### Complete example for `release`

Combining the individual examples given above for `release` results in the following
code snippets. There are two options, depending on how you generate the
tags. These options cannot be used together, so choose one:

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
  ```

- To create a release automatically when commits are pushed or merged to the default branch,
  using a new Git tag that is defined with variables:

  NOTE: **Note:**
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
  ```

#### Release assets as Generic packages

You can use [Generic packages](../../user/packages/generic_packages/) to host your release assets.
For a complete example, see the [Release assets as Generic packages](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs/examples/release-assets-as-generic-package/)
project.

#### `releaser-cli` command line

The entries under the `release` node are transformed into a `bash` command line and sent
to the Docker container, which contains the [release-cli](https://gitlab.com/gitlab-org/release-cli).
You can also call the `release-cli` directly from a `script` entry.

For example, using the YAML described above:

```shell
release-cli create --name "Release $CI_COMMIT_SHA" --description "Created using the release-cli $EXTRA_DESCRIPTION" --tag-name "v${MAJOR}.${MINOR}.${REVISION}" --ref "$CI_COMMIT_SHA" --released-at "2020-07-15T08:00:00Z" --milestone "m1" --milestone "m2" --milestone "m3"
```

### `secrets`

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/33014) in GitLab 13.4.

`secrets` indicates the [CI Secrets](../secrets/index.md) this job needs. It should be a hash,
and the keys should be the names of the environment variables that are made available to the job.
The value of each secret is saved in a temporary file. This file's path is stored in these
environment variables.

#### `secrets:vault` **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/28321) in GitLab 13.4.

`vault` keyword specifies secrets provided by [Hashicorp's Vault](https://www.vaultproject.io/).
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

### `pages`

`pages` is a special job that is used to upload static content to GitLab that
can be used to serve your website. It has a special syntax, so the two
requirements below must be met:

- Any static content must be placed under a `public/` directory.
- `artifacts` with a path to the `public/` directory must be defined.

The example below moves all files from the root of the project to the
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
  only:
    - master
```

Read more on [GitLab Pages user documentation](../../user/project/pages/index.md).

## `variables`

> Introduced in GitLab Runner v0.5.0.

[CI/CD variables](../variables/README.md) are configurable values that are passed to jobs.
They can be set globally and per-job.

There are two types of variables.

- [Custom variables](../variables/README.md#custom-environment-variables):
  You can define their values in the `.gitlab-ci.yml` file, in the GitLab UI,
  or by using the API.
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
[job-specific variable is used](../variables/README.md#priority-of-environment-variables).

All YAML-defined variables are also set to any linked
[Docker service containers](../docker/using_docker_images.md#what-is-a-service).

You can use [YAML anchors for variables](#yaml-anchors-for-variables).

### Configure runner behavior with variables

You can use [CI/CD variables](../variables/README.md) to configure runner Git behavior:

- [`GIT_STRATEGY`](../runners/README.md#git-strategy)
- [`GIT_SUBMODULE_STRATEGY`](../runners/README.md#git-submodule-strategy)
- [`GIT_CHECKOUT`](../runners/README.md#git-checkout)
- [`GIT_CLEAN_FLAGS`](../runners/README.md#git-clean-flags)
- [`GIT_FETCH_EXTRA_FLAGS`](../runners/README.md#git-fetch-extra-flags)
- [`GIT_DEPTH`](../runners/README.md#shallow-cloning) (shallow cloning)
- [`GIT_CLONE_PATH`](../runners/README.md#custom-build-directories) (custom build directories)

You can also use variables to configure how many times a runner
[attempts certain stages of job execution](../runners/README.md#job-stages-attempts).

## Special YAML features

It's possible to use special YAML features like anchors (`&`), aliases (`*`)
and map merging (`<<`). Use these features to reduce the complexity
of `.gitlab-ci.yml`.

Read more about the various [YAML features](https://learnxinyminutes.com/docs/yaml/).

In most cases, the [`extends` keyword](#extends) is more user friendly and should
be used over these special YAML features. YAML anchors may still
need to be used to merge arrays.

### Anchors

YAML has a feature called 'anchors' that you can use to duplicate
content across your document.

Use anchors to duplicate or inherit properties. Use anchors with [hidden jobs](#hide-jobs)
to provide templates for your jobs. When there are duplicate keys, GitLab
performs a reverse deep merge based on the keys.

You can't use YAML anchors across multiple files when leveraging the [`include`](#include)
feature. Anchors are only valid in the file they were defined in. Instead
of using YAML anchors, you can use the [`extends` keyword](#extends).

The following example uses anchors and map merging. It creates two jobs,
`test1` and `test2`, that inherit the `.job_template` configuration, each
with their own custom `script` defined:

```yaml
.job_template: &job_definition  # Hidden key that defines an anchor named 'job_definition'
  image: ruby:2.6
  services:
    - postgres
    - redis

test1:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test1 project

test2:
  <<: *job_definition           # Merge the contents of the 'job_definition' alias
  script:
    - test2 project
```

`&` sets up the name of the anchor (`job_definition`), `<<` means "merge the
given hash into the current one", and `*` includes the named anchor
(`job_definition` again). The expanded version of the example above is:

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
.job_template: &job_definition
  script:
    - test project
  tags:
    - dev

.postgres_services:
  services: &postgres_definition
    - postgres
    - ruby

.mysql_services:
  services: &mysql_definition
    - mysql
    - ruby

test:postgres:
  <<: *job_definition
  services: *postgres_definition
  tags:
    - postgres

test:mysql:
  <<: *job_definition
  services: *mysql_definition
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
`tags: [dev]` has been overwritten by `tags: [postgres]`.

#### YAML anchors for scripts

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/23005) in GitLab 12.5.

You can use [YAML anchors](#anchors) with [script](#script), [`before_script`](#before_script),
and [`after_script`](#after_script) to use predefined commands in multiple jobs:

```yaml
.some-script: &some-script
  - echo "Execute this script in `before_script` sections"

.some-script-before: &some-script-before
  - echo "Execute this script in `script` sections"

.some-script-after: &some-script-after
  - echo "Execute this script in `after_script` sections"

job_name:
  before_script:
    - *some-script-before
  script:
    - *some-script
  before_script:
    - *some-script-after
```

#### YAML anchors for variables

[YAML anchors](#anchors) can be used with `variables`, to repeat assignment
of variables across multiple jobs. Use can also use YAML anchors when a job
requires a specific `variables` block that would otherwise override the global variables.

In the example below, we override the `GIT_STRATEGY` variable without affecting
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

If you want to temporarily 'disable' a job, rather than commenting out all the
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
[special YAML features](#special-yaml-features) and transform the hidden jobs
into templates.

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
[pipelines for merge requests](../merge_request_pipelines/index.md).

## Deprecated keywords

The following keywords are deprecated.

### Globally-defined `types`

DANGER: **Deprecated:**
`types` is deprecated, and could be removed in a future release.
Use [`stages`](#stages) instead.

### Job-defined `type`

DANGER: **Deprecated:**
`type` is deprecated, and could be removed in one of the future releases.
Use [`stage`](#stage) instead.

### Globally-defined `image`, `services`, `cache`, `before_script`, `after_script`

Defining `image`, `services`, `cache`, `before_script`, and
`after_script` globally is deprecated. Support could be removed
from a future release.

Use [`default:`](#global-defaults) instead. For example:

```yaml
default:
  image: ruby:2.5
  services:
    - docker:dind
  cache:
    paths: [vendor/]
  before_script:
    - bundle install --path vendor/
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
