---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Use CI/CD variables in job scripts
description: Configuration, usage, and security.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

All CI/CD variables are set as environment variables in the job's environment.
You can use variables in job scripts with the standard formatting for each environment's
shell.

To access environment variables, use the syntax for your [runner executor's shell](https://docs.gitlab.com/runner/executors/).

## With Bash, `sh` and similar

To access environment variables in Bash, `sh`, and similar shells, prefix the
CI/CD variable with (`$`):

```yaml
job_name:
  script:
    - echo "$CI_JOB_ID"
```

## With PowerShell

To access variables in a Windows PowerShell environment, including environment
variables set by the system, prefix the variable name with `$env:` or `$`:

```yaml
job_name:
  script:
    - echo $env:CI_JOB_ID
    - echo $CI_JOB_ID
    - echo $env:PATH
```

In [some cases](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4115#note_157692820)
environment variables must be surrounded by quotes to expand properly:

```yaml
job_name:
  script:
    - D:\\qislsf\\apache-ant-1.10.5\\bin\\ant.bat "-DsosposDailyUsr=$env:SOSPOS_DAILY_USR" portal_test
```

## With Windows Batch

To access CI/CD variables in Windows Batch, surround the variable with `%`:

```yaml
job_name:
  script:
    - echo %CI_JOB_ID%
```

You can also surround the variable with `!` for [delayed expansion](https://ss64.com/nt/delayedexpansion.html).
Delayed expansion might be needed for variables that contain white spaces or newlines:

```yaml
job_name:
  script:
    - echo !ERROR_MESSAGE!
```

## In service containers

[Service containers](../docker/using_docker_images.md) can use CI/CD variables, but
by default can only access [variables saved in the `.gitlab-ci.yml` file](_index.md#define-a-cicd-variable-in-the-gitlab-ciyml-file).
Variables [added in the GitLab UI](_index.md#define-a-cicd-variable-in-the-ui) are not available to
service containers, because service containers are not trusted by default.

To make a UI-defined variable available in a service container, you can re-assign
it to another variable in your `.gitlab-ci.yml`:

```yaml
variables:
  SA_PASSWORD_YAML_FILE: $SA_PASSWORD_UI
```

The re-assigned variable cannot have the same name as the original variable. Otherwise it does not get expanded.

## Pass an environment variable to another job

You can create a new environment variable in a job, and pass it to another job
in a later stage. These variables cannot be used as CI/CD variables to configure a pipeline
(for example with the [`rules` keyword](../yaml/_index.md#rules)), but they can be used in job scripts.

To pass a job-created environment variable to other jobs:

1. In the job script, save the variable as a `.env` file.
   - The format of the file must be one variable definition per line.
   - Each line must be formatted as: `VARIABLE_NAME=ANY VALUE HERE`.
   - Values can be wrapped in quotes, but cannot contain newline characters.
1. Save the `.env` file as an [`artifacts:reports:dotenv`](../yaml/artifacts_reports.md#artifactsreportsdotenv)
   artifact.
1. Jobs in later stages can then use the variable in scripts, unless
   [jobs are configured to not receive `dotenv` variables](#control-which-jobs-receive-dotenv-variables).

For example:

```yaml
build-job:
  stage: build
  script:
    - echo "BUILD_VARIABLE=value_from_build_job" >> build.env
  artifacts:
    reports:
      dotenv: build.env

test-job:
  stage: test
  script:
    - echo "$BUILD_VARIABLE"  # Output is: 'value_from_build_job'
```

Variables from `dotenv` reports [take precedence](_index.md#cicd-variable-precedence) over
certain types of new variable definitions such as job defined variables.

You can also [pass `dotenv` variables to downstream pipelines](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job).

### Control which jobs receive `dotenv` variables

You can use the [`dependencies`](../yaml/_index.md#dependencies) or [`needs`](../yaml/_index.md#needs)
keywords to control which jobs receive the `dotenv` artifacts.

To have no environment variables from a `dotenv` artifact:

- Pass an empty `dependencies` or `needs` array.
- Pass [`needs:artifacts`](../yaml/_index.md#needsartifacts) as `false`.
- Set `needs` to only list jobs that do not have a `dotenv` artifact.

For example:

```yaml
build-job1:
  stage: build
  script:
    - echo "BUILD_VERSION=v1.0.0" >> build.env
  artifacts:
    reports:
      dotenv: build.env

build-job2:
  stage: build
  needs: []
  script:
    - echo "This job has no dotenv artifacts"

test-job1:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is: 'v1.0.0'
  dependencies:
    - build-job1

test-job2:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is ''
  dependencies: []

test-job3:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is: 'v1.0.0'
  needs:
    - build-job1

test-job4:
  stage: test
  script:
    - echo "$BUILD_VERSION"  # Output is: 'v1.0.0'
  needs:
    - job: build-job1
      artifacts: true

test-job5:
  stage: deploy
  script:
    - echo "$BUILD_VERSION"  # Output is ''
  needs:
    - job: build-job1
      artifacts: false

test-job6:
  stage: deploy
  script:
    - echo "$BUILD_VERSION"  # Output is ''
  needs:
    - build-job2
```

## Pass an environment variable from the `script` section to `artifacts` or `cache`

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29391) in GitLab 16.4.

{{< /history >}}

Use `$GITLAB_ENV` to use environment variables defined in the `script` section in the
`artifacts` or `cache` keywords. For example:

```yaml
build-job:
  stage: build
  script:
    - echo "ARCH=$(arch)" >> $GITLAB_ENV
    - touch some-file-$(arch)
  artifacts:
    paths:
      - some-file-$ARCH
```

## Store multiple values in one variable

You cannot create a CI/CD variable that is an array of values, but you
can use shell scripting techniques for similar behavior.

For example, you can store multiple values separated by a space in a variable,
then loop through the values with a script:

```yaml
job1:
  variables:
    FOLDERS: src test docs
  script:
    - |
      for FOLDER in $FOLDERS
        do
          echo "The path is root/${FOLDER}"
        done
```

## Use CI/CD variables in other variables

You can use variables inside other variables:

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
```

### As part of a string

You can use variables as part of a string. You can surround the variables with curly brackets (`{}`)
to help distinguish the variable name from the surrounding text. Without curly brackets,
the adjacent text is interpreted as part of the variable name. For example:

```yaml
job:
  variables:
    FLAGS: '-al'
    DIR: 'path/to/directory'
    LS_CMD: 'ls "$FLAGS"'
    CD_CMD: 'cd "${DIR}_files"'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al'
    - 'eval "$CD_CMD"'  # Executes 'cd path/to/directory_files'
```

### Use the `$` character in CI/CD variables

If you do not want the `$` character interpreted as the start of another variable,
use `$$` instead:

```yaml
job:
  variables:
    FLAGS: '-al'
    LS_CMD: 'ls "$FLAGS" $$TMP_DIR'
  script:
    - 'eval "$LS_CMD"'  # Executes 'ls -al $TMP_DIR'
```

This does not work when [passing a CI/CD variable to a downstream pipeline](../pipelines/downstream_pipelines_troubleshooting.md#variable-with--character-does-not-get-passed-to-a-downstream-pipeline-properly).
