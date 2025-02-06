---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Where variables can be used
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

As it's described in the [CI/CD variables](_index.md) documentation, you can
define many different variables. Some of them can be used for all GitLab CI/CD
features, but some of them are more or less limited.

This document describes where and how the different types of variables can be used.

## Variables usage

There are two places defined variables can be used. On the:

1. GitLab side, in the `.gitlab-ci.yml` file.
1. The GitLab Runner side, in `config.toml`.

### `.gitlab-ci.yml` file

> - Support for `CI_ENVIRONMENT_*` variables except `CI_ENVIRONMENT_SLUG` [introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/128694) in GitLab 16.4.

| Definition                                                            | Can be expanded? | Expansion place        | Description |
|:----------------------------------------------------------------------|:-----------------|:-----------------------|:------------|
| [`after_script`](../yaml/_index.md#after_script)                       | yes              | Script execution shell | The variable expansion is made by the [execution shell environment](#execution-shell-environment). |
| [`artifacts:name`](../yaml/_index.md#artifactsname)                    | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`artifacts:paths`](../yaml/_index.md#artifactspaths)                  | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`artifacts:exclude`](../yaml/_index.md#artifactsexclude)              | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`before_script`](../yaml/_index.md#before_script)                     | yes              | Script execution shell | The variable expansion is made by the [execution shell environment](#execution-shell-environment) |
| [`cache:key`](../yaml/_index.md#cachekey)                              | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`cache:paths`](../yaml/_index.md#cachepaths)                          | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`cache:policy`](../yaml/_index.md#cachepolicy)                        | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`environment:name`](../yaml/_index.md#environmentname)                | yes              | GitLab                 | Similar to `environment:url`, but the variables expansion doesn't support the following:<br/><br/>- `CI_ENVIRONMENT_*` variables.<br/>- [Persisted variables](#persisted-variables). |
| [`environment:url`](../yaml/_index.md#environmenturl)                  | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab.<br/><br/>Supported are all variables defined for a job (project/group variables, variables from `.gitlab-ci.yml`, variables from triggers, variables from pipeline schedules).<br/><br/>Not supported are variables defined in the GitLab Runner `config.toml` and variables created in the job's `script`. |
| [`environment:auto_stop_in`](../yaml/_index.md#environmentauto_stop_in)| yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab.<br/><br/> The value of the variable being substituted should be a period of time in a human readable natural language form. See [supported values](../yaml/_index.md#environmentauto_stop_in) for more information.|
| [`id_tokens:aud`](../yaml/_index.md#id_tokens)                         | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab. Variable expansion [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/414293) in GitLab 16.1. |
| [`image`](../yaml/_index.md#image)                                     | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`include`](../yaml/_index.md#include)                                 | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab. <br/><br/>See [Use variables with include](../yaml/includes.md#use-variables-with-include) for more information on supported variables. |
| [`resource_group`](../yaml/_index.md#resource_group)                   | yes              | GitLab                 | Similar to `environment:url`, but the variables expansion doesn't support the following:<br/>- `CI_ENVIRONMENT_URL`<br/>- [Persisted variables](#persisted-variables). |
| [`rules:changes`](../yaml/_index.md#ruleschanges)                      | no               | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab. |
| [`rules:changes:compare_to`](../yaml/_index.md#ruleschangescompare_to) | no               | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab. |
| [`rules:exists`](../yaml/_index.md#rulesexists)                        | no               | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab. |
| [`rules:if`](../yaml/_index.md#rulesif)                                | no               | Not applicable         | The variable must be in the form of `$variable`. Not supported are the following:<br/><br/>- `CI_ENVIRONMENT_SLUG` variable.<br/>- [Persisted variables](#persisted-variables). |
| [`script`](../yaml/_index.md#script)                                   | yes              | Script execution shell | The variable expansion is made by the [execution shell environment](#execution-shell-environment). |
| [`services:name`](../yaml/_index.md#services)                          | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`services`](../yaml/_index.md#services)                               | yes              | Runner                 | The variable expansion is made by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`tags`](../yaml/_index.md#tags)                                       | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab.  |
| [`trigger` and `trigger:project`](../yaml/_index.md#trigger)           | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab. Variable expansion for `trigger:project` [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/367660) in GitLab 15.3. |
| [`variables`](../yaml/_index.md#variables)                             | yes              | GitLab/Runner          | The variable expansion is first made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab, and then any unrecognized or unavailable variables are expanded by GitLab Runner's [internal variable expansion mechanism](#gitlab-runner-internal-variable-expansion-mechanism). |
| [`workflow:name`](../yaml/_index.md#workflowname)                      | yes              | GitLab                 | The variable expansion is made by the [internal variable expansion mechanism](#gitlab-internal-variable-expansion-mechanism) in GitLab.<br/><br/>Supported are all variables available in `workflow`:<br/>- Project/Group variables.<br/>- Global `variables` and `workflow:rules:variables` (when matching the rule).<br/>- Variables inherited from parent pipelines.<br/>- Variables from triggers.<br/>- Variables from pipeline schedules.<br/><br/>Not supported are variables defined in the GitLab Runner `config.toml`, variables defined in jobs, or [Persisted variables](#persisted-variables). |

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

GitLab expands job variable values recursively before sending them to the runner. For example, in the following scenario:

```yaml
- BUILD_ROOT_DIR: '${CI_BUILDS_DIR}'
- OUT_PATH: '${BUILD_ROOT_DIR}/out'
- PACKAGE_PATH: '${OUT_PATH}/pkg'
```

The runner receives a valid, fully-formed path. For example, if `${CI_BUILDS_DIR}` is `/output`, then `PACKAGE_PATH` would be `/output/out/pkg`.

References to unavailable variables are left intact. In this case, the runner
[attempts to expand the variable value](#gitlab-runner-internal-variable-expansion-mechanism) at runtime.
For example, a variable like `CI_BUILDS_DIR` is known by the runner only at runtime.

### GitLab Runner internal variable expansion mechanism

- Supported: project/group variables, `.gitlab-ci.yml` variables, `config.toml` variables, and
  variables from triggers, pipeline schedules, and manual pipelines.
- Not supported: variables defined inside of scripts (for example, `export MY_VARIABLE="test"`).

The runner uses Go's `os.Expand()` method for variable expansion. It means that it handles
only variables defined as `$variable` and `${variable}`. What's also important, is that
the expansion is done only once, so nested variables may or may not work, depending on the
ordering of variables definitions, and whether [nested variable expansion](#nested-variable-expansion)
is enabled in GitLab.

For artifacts and cache uploads, the runner uses
[mvdan.cc/sh/v3/expand](https://pkg.go.dev/mvdan.cc/sh/v3/expand) for variable
expansion instead of Go's `os.Expand()` because `mvdan.cc/sh/v3/expand` supports
[parameter expansion](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html).

### Execution shell environment

This is an expansion phase that takes place during the `script` execution.
Its behavior depends on the shell used (`bash`, `sh`, `cmd`, PowerShell). For example, if the job's
`script` contains a line `echo $MY_VARIABLE-${MY_VARIABLE_2}`, it should be properly handled
by bash/sh (leaving empty strings or some values depending whether the variables were
defined or not), but don't work with Windows' `cmd` or PowerShell, since these shells
use a different variables syntax.

Supported:

- The `script` may use all available variables that are default for the shell (for example, `$PATH` which
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
[separated shell context](../yaml/_index.md#after_script).

## Persisted variables

Some predefined variables are called "persisted". Persisted variables are:

- Supported for definitions where the ["Expansion place"](#gitlab-ciyml-file) is:
  - Runner.
  - Script execution shell.
- Not supported:
  - For definitions where the ["Expansion place"](#gitlab-ciyml-file) is GitLab.
  - In `rules` [variables expressions](../jobs/job_rules.md#cicd-variable-expressions).

[Pipeline trigger jobs](../yaml/_index.md#trigger) cannot use job-level persisted variables,
but can use pipeline-level persisted variables.

Some of the persisted variables contain tokens and cannot be used by some definitions
due to security reasons.

Pipeline-level persisted variables:

- `CI_PIPELINE_ID`
- `CI_PIPELINE_URL`

Job-level persisted variables:

- `CI_DEPLOY_PASSWORD`
- `CI_DEPLOY_USER`
- `CI_JOB_ID`
- `CI_JOB_STARTED_AT`
- `CI_JOB_TOKEN`
- `CI_JOB_URL`
- `CI_REGISTRY_PASSWORD`
- `CI_REGISTRY_USER`
- `CI_REPOSITORY_URL`

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
