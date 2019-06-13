---
type: reference
---

# Where variables can be used

As it's described in the [CI/CD variables](README.md) docs, you can
define many different variables. Some of them can be used for all GitLab CI/CD
features, but some of them are more or less limited.

This document describes where and how the different types of variables can be used.

## Variables usage

There are two places defined variables can be used. On the:

1. GitLab side, in `.gitlab-ci.yml`.
1. The runner side, in `config.toml`.

### `.gitlab-ci.yml` file

| Definition                                 | Can be expanded? | Expansion place        | Description                                                                                                                                                                                                                                                                                                                                                                                                                       |
|:-------------------------------------------|:-----------------|:-----------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `environment:url`                          | yes              | GitLab                 | The variable expansion is made by GitLab's [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism).<br/><br/>Supported are all variables defined for a job (project/group variables, variables from `.gitlab-ci.yml`, variables from triggers, variables from pipeline schedules).<br/><br/>Not supported are variables defined in Runner's `config.toml` and variables created in job's `script`. |
| `environment:name`                         | yes              | GitLab                 | Similar to `environment:url`, but the variables expansion doesn't support the following:<br/><br/>- Variables that are based on the environment's name (`CI_ENVIRONMENT_NAME`, `CI_ENVIRONMENT_SLUG`).<br/>- Any other variables related to environment (currently only `CI_ENVIRONMENT_URL`).<br/>- [Persisted variables](#persisted-variables).                                                                                 |
| `variables`                                | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `image`                                    | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `services:[]`                              | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `services:[]:name`                         | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `cache:key`                                | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `artifacts:name`                           | yes              | Runner                 | The variable expansion is made by GitLab Runner's shell environment                                                                                                                                                                                                                                                                                                                                                               |
| `script`, `before_script`, `after_script`  | yes              | Script execution shell | The variable expansion is made by the [execution shell environment](#execution-shell-environment)                                                                                                                                                                                                                                                                                                                                 |
| `only:variables:[]`, `except:variables:[]` | no               | n/a                    | The variable must be in the form of `$variable`. Not supported are the following:<br/><br/>- Variables that are based on the environment's name (`CI_ENVIRONMENT_NAME`, `CI_ENVIRONMENT_SLUG`).<br/>- Any other variables related to environment (currently only `CI_ENVIRONMENT_URL`).<br/>- [Persisted variables](#persisted-variables).                                                                                            |

### `config.toml` file

NOTE: **Note:**
You can read more about `config.toml` in the [Runner's docs](https://docs.gitlab.com/runner/configuration/advanced-configuration.html).

| Definition                           | Can be expanded? | Description                                                                                                                                  |
|:-------------------------------------|:-----------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| `runners.environment`                | yes              | The variable expansion is made by the Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism) |
| `runners.kubernetes.pod_labels`      | yes              | The Variable expansion is made by the Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism) |
| `runners.kubernetes.pod_annotations` | yes              | The Variable expansion is made by the Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism) |

## Expansion mechanisms

There are three expansion mechanisms:

- GitLab
- GitLab Runner
- Execution shell environment

### GitLab internal variable expansion mechanism

The expanded part needs to be in a form of `$variable`, or `${variable}` or `%variable%`.
Each form is handled in the same way, no matter which OS/shell will finally handle the job,
since the expansion is done in GitLab before any Runner will get the job.

### GitLab Runner internal variable expansion mechanism

- Supported: project/group variables, `.gitlab-ci.yml` variables, `config.toml` variables, and
  variables from triggers, pipeline schedules, and manual pipelines.
- Not supported: variables defined inside of scripts (e.g., `export MY_VARIABLE="test"`).

The Runner uses Go's `os.Expand()` method for variable expansion. It means that it will handle
only variables defined as `$variable` and `${variable}`. What's also important, is that
the expansion is done only once, so nested variables may or may not work, depending on the
ordering of variables definitions.

### Execution shell environment

This is an expansion that takes place during the `script` execution.
How it works depends on the used shell (bash/sh/cmd/PowerShell). For example, if the job's
`script` contains a line `echo $MY_VARIABLE-${MY_VARIABLE_2}`, it should be properly handled
by bash/sh (leaving empty strings or some values depending whether the variables were
defined or not), but will not work with Windows' cmd/PowerShell, since these shells
are using a different variables syntax.

Supported:

- The `script` may use all available variables that are default for the shell (e.g., `$PATH` which
  should be present in all bash/sh shells) and all variables defined by GitLab CI/CD (project/group variables,
  `.gitlab-ci.yml` variables, `config.toml` variables, and variables from triggers and pipeline schedules).
- The `script` may also use all variables defined in the lines before. So, for example, if you define
  a variable `export MY_VARIABLE="test"`:
  - In `before_script`, it will work in the following lines of `before_script` and
    all lines of the related `script`.
  - In `script`, it will work in the following lines of `script`.
  - In `after_script`, it will work in following lines of `after_script`.

Please notice the specific case of `after_script` scripts, that can:

- Only use variables defined before the script within the same `after_script` section.
- Not use variables defined in `before_script` and `script`.

Both restrictions are caused by the fact, that `after_script` script is executed in a
[separated shell context](https://docs.gitlab.com/ee/ci/yaml/README.html#before_script-and-after_script).

## Persisted variables

NOTE: **Note:**
Some of the persisted variables contain tokens and cannot be used by some definitions
due to security reasons.

The following variables are known as "persisted":

- `CI_PIPELINE_ID`
- `CI_JOB_ID`
- `CI_JOB_TOKEN`
- `CI_BUILD_ID`
- `CI_BUILD_TOKEN`
- `CI_REGISTRY_USER`
- `CI_REGISTRY_PASSWORD`
- `CI_REPOSITORY_URL`
- `CI_DEPLOY_USER`
- `CI_DEPLOY_PASSWORD`

They are:

- Supported for definitions where the ["Expansion place"](#gitlab-ciyml-file) is:
  - Runner.
  - Script execution shell.
- Not supported:
  - For definitions where the ["Expansion place"](#gitlab-ciyml-file) is GitLab.
  - In the `only` and `except` [variables expressions](README.md#environment-variables-expressions).

## Variables with an environment scope

Variables defined with an environment scope are supported. Given that
there is a variable `$STAGING_SECRET` defined in a scope of
`review/staging/*`, the following job that is using dynamic environments
is going to be created, based on the matching variable expression:

```yaml
my-job:
  stage: staging
  environment:
    name: review/$CI_JOB_STAGE/deploy
  script:
    - 'deploy staging'
  only:
    variables:
      - $STAGING_SECRET == 'something'
```
