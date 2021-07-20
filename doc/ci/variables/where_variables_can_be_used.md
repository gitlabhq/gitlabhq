---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Where variables can be used

As it's described in the [CI/CD variables](index.md) docs, you can
define many different variables. Some of them can be used for all GitLab CI/CD
features, but some of them are more or less limited.

This document describes where and how the different types of variables can be used.

## Variables usage

There are two places defined variables can be used. On the:

1. GitLab side, in `.gitlab-ci.yml`.
1. The GitLab Runner side, in `config.toml`.

### `.gitlab-ci.yml` file

| Definition                                 | Can be expanded? | Expansion place        | Description                                                                                                                                                                                                                                                                                                                                                                                                                       |
|:-------------------------------------------|:-----------------|:-----------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `environment:url`                          | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab.<br/><br/>Supported are all variables defined for a job (project/group variables, variables from `.gitlab-ci.yml`, variables from triggers, variables from pipeline schedules).<br/><br/>Not supported are variables defined in the GitLab Runner `config.toml` and variables created in the job's `script`. |
| `environment:name`                         | yes              | GitLab                 | Similar to `environment:url`, but the variables expansion doesn't support the following:<br/><br/>- Variables that are based on the environment's name (`CI_ENVIRONMENT_NAME`, `CI_ENVIRONMENT_SLUG`).<br/>- Any other variables related to environment (currently only `CI_ENVIRONMENT_URL`).<br/>- [Persisted variables](#persisted-variables).                                                                                 |
| `resource_group`                           | yes              | GitLab                 | Similar to `environment:url`, but the variables expansion doesn't support the following:<br/><br/>- Variables that are based on the environment's name (`CI_ENVIRONMENT_NAME`, `CI_ENVIRONMENT_SLUG`).<br/>- Any other variables related to environment (currently only `CI_ENVIRONMENT_URL`).<br/>- [Persisted variables](#persisted-variables).                                                                                 |
| `include`                                  | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab. <br/><br/>Predefined project variables are supported: `GITLAB_FEATURES`, `CI_DEFAULT_BRANCH`, and all variables that start with `CI_PROJECT_` (for example `CI_PROJECT_NAME`).                                                                                                            |
| `variables`                                | yes              | GitLab/Runner          | The variable expansion is first made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab, and then any unrecognized or unavailable variables are expanded by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism).                                                                                                   |
| `image`                                    | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `services:[]`                              | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `services:[]:name`                         | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `cache:key`                                | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism)                                                                                                                                                                                                                                                                                   |
| `artifacts:name`                           | yes              | Runner                 | The variable expansion is made by GitLab Runner's shell environment                                                                                                                                                                                                                                                                                                                                                               |
| `script`, `before_script`, `after_script`  | yes              | Script execution shell | The variable expansion is made by the [execution shell environment](#execution-shell-environment)                                                                                                                                                                                                                                                                                                                                 |
| `only:variables:[]`, `except:variables:[]`, `rules:if` | no   | n/a                    | The variable must be in the form of `$variable`. Not supported are the following:<br/><br/>- Variables that are based on the environment's name (`CI_ENVIRONMENT_NAME`, `CI_ENVIRONMENT_SLUG`).<br/>- Any other variables related to environment (currently only `CI_ENVIRONMENT_URL`).<br/>- [Persisted variables](#persisted-variables).                                                                                        |

### `config.toml` file

| Definition                           | Can be expanded? | Description                                                                                                                                  |
|:-------------------------------------|:-----------------|:---------------------------------------------------------------------------------------------------------------------------------------------|
| `runners.environment`                | yes              | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism) |
| `runners.kubernetes.pod_labels`      | yes              | The Variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism) |
| `runners.kubernetes.pod_annotations` | yes              | The Variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism) |

You can read more about `config.toml` in the [GitLab Runner docs](https://docs.gitlab.com/runner/configuration/advanced-configuration.html).

## Expansion mechanisms

There are three expansion mechanisms:

- GitLab
- GitLab Runner
- Execution shell environment

### GitLab internal variable expansion mechanism

The expanded part needs to be in a form of `$variable`, or `${variable}` or `%variable%`.
Each form is handled in the same way, no matter which OS/shell handles the job,
because the expansion is done in GitLab before any runner gets the job.

#### Nested variable expansion

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/48627) in GitLab 13.10.
> - It's [deployed behind a feature flag](../../user/feature_flags.md), disabled by default.
> - It can be enabled or disabled for a single project.
> - It's disabled on GitLab.com.
> - To use it in GitLab self-managed instances, ask a GitLab administrator to [enable it](#enabling-the-nested-variable-expansion-feature). **(FREE SELF)**

GitLab expands job variable values recursively before sending them to the runner. For example:

```yaml
- BUILD_ROOT_DIR: '${CI_BUILDS_DIR}'
- OUT_PATH: '${BUILD_ROOT_DIR}/out'
- PACKAGE_PATH: '${OUT_PATH}/pkg'
```

If nested variable expansion is:

- **Disabled**: the runner receives `${BUILD_ROOT_DIR}/out/pkg`. This is not a valid path.
- **Enabled**: the runner receives a valid, fully-formed path. For example, if `${CI_BUILDS_DIR}` is `/output`, then `PACKAGE_PATH` would be `/output/out/pkg`.

References to unavailable variables are left intact. In this case, the runner
[attempts to expand the variable value](#gitlab-runner-internal-variable-expansion-mechanism) at runtime.
For example, a variable like `CI_BUILDS_DIR` is known by the runner only at runtime.

##### Enabling the nested variable expansion feature **(FREE SELF)**

This feature comes with the `:variable_inside_variable` feature flag disabled by default.

To enable this feature, ask a GitLab administrator with [Rails console access](../../administration/feature_flags.md#how-to-enable-and-disable-features-behind-flags) to run the
following command:

```ruby
# For the instance
Feature.enable(:variable_inside_variable)
# For a single project
Feature.enable(:variable_inside_variable, Project.find(<project id>))
```

To disable it:

```ruby
# For the instance
Feature.disable(:variable_inside_variable)
# For a single project
Feature.disable(:variable_inside_variable, Project.find(<project id>))
```

### GitLab Runner internal variable expansion mechanism

- Supported: project/group variables, `.gitlab-ci.yml` variables, `config.toml` variables, and
  variables from triggers, pipeline schedules, and manual pipelines.
- Not supported: variables defined inside of scripts (e.g., `export MY_VARIABLE="test"`).

The runner uses Go's `os.Expand()` method for variable expansion. It means that it handles
only variables defined as `$variable` and `${variable}`. What's also important, is that
the expansion is done only once, so nested variables may or may not work, depending on the
ordering of variables definitions, and whether [nested variable expansion](#nested-variable-expansion)
is enabled in GitLab.

### Execution shell environment

This is an expansion phase that takes place during the `script` execution.
Its behavior depends on the shell used (`bash`, `sh`, `cmd`, PowerShell). For example, if the job's
`script` contains a line `echo $MY_VARIABLE-${MY_VARIABLE_2}`, it should be properly handled
by bash/sh (leaving empty strings or some values depending whether the variables were
defined or not), but don't work with Windows' `cmd` or PowerShell, since these shells
use a different variables syntax.

Supported:

- The `script` may use all available variables that are default for the shell (e.g., `$PATH` which
  should be present in all bash/sh shells) and all variables defined by GitLab CI/CD (project/group variables,
  `.gitlab-ci.yml` variables, `config.toml` variables, and variables from triggers and pipeline schedules).
- The `script` may also use all variables defined in the lines before. So, for example, if you define
  a variable `export MY_VARIABLE="test"`:
  - In `before_script`, it works in the subsequent lines of `before_script` and
    all lines of the related `script`.
  - In `script`, it works in the subsequent lines of `script`.
  - In `after_script`, it works in subsequent lines of `after_script`.

In the case of `after_script` scripts, they can:

- Only use variables defined before the script within the same `after_script`
  section.
- Not use variables defined in `before_script` and `script`.

These restrictions exist because `after_script` scripts are executed in a
[separated shell context](../yaml/index.md#after_script).

## Persisted variables

The following variables are known as "persisted":

- `CI_PIPELINE_ID`
- `CI_JOB_ID`
- `CI_JOB_TOKEN`
- `CI_JOB_STARTED_AT`
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
  - In the `only` and `except` [variables expressions](../jobs/job_control.md#cicd-variable-expressions).

Some of the persisted variables contain tokens and cannot be used by some definitions
due to security reasons.

## Variables with an environment scope

Variables defined with an environment scope are supported. Given that
there is a variable `$STAGING_SECRET` defined in a scope of
`review/staging/*`, the following job that is using dynamic environments
is created, based on the matching variable expression:

```yaml
my-job:
  stage: staging
  environment:
    name: review/$CI_JOB_STAGE/deploy
  script:
    - 'deploy staging'
  rules:
    - if: $STAGING_SECRET == 'something'
```
