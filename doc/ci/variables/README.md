---
stage: Verify
group: Continuous Integration
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
type: reference
---

# GitLab CI/CD environment variables

An environment variable is a dynamically-named value that can
affect the way running processes behave on an operating
system.

Environment variables are part of the environment in which a process runs.
For example, a running process can query the value of the
`TEMP` environment variable to discover a suitable location
to store temporary files, or to define a `URL` for a database
that can be reused in different scripts.

Variables are useful for customizing your jobs in GitLab CI/CD.
When you use variables, you don't have to hard-code values.

> For more information about advanced use of GitLab CI/CD:
>
> - <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>&nbsp;Get to productivity faster with these [7 advanced GitLab CI workflow hacks](https://about.gitlab.com/webcast/7cicd-hacks/)
>   shared by GitLab engineers.
> - <i class="fa fa-youtube-play youtube" aria-hidden="true"></i>&nbsp;Learn how the Cloud Native Computing Foundation (CNCF) [eliminates the complexity](https://about.gitlab.com/customers/cncf/)
>   of managing projects across many cloud providers with GitLab CI/CD.

## Predefined environment variables

GitLab CI/CD has a [default set of predefined variables](predefined_variables.md)
that you can use without any additional specification.
You can call issue numbers, user names, branch names,
pipeline and commit IDs, and much more.

Predefined environment variables are provided by GitLab
for the local environment of the Runner.

GitLab reads the `.gitlab-ci.yml` file and sends the information
to the Runner, where the variables are exposed. The Runner then runs the script commands.

### Use predefined environment variables

You can choose one of the existing predefined variables
to be output by the Runner.

This example shows how to output a job's stage by using the predefined variable `CI_JOB_STAGE`.

In your `.gitlab-ci.yml` file, call the variable from your script. Ensure
you use the correct [syntax](#syntax-of-environment-variables-in-job-scripts).

```yaml
test_variable:
  stage: test
  script:
    - echo $CI_JOB_STAGE
```

In this case, the Runner outputs the `stage` for the
job `test_variable`, which is `test`:

![Output `$CI_JOB_STAGE`](img/ci_job_stage_output_example.png)

As another example, let's say you're using your own GitLab
instance and you want to know what domain your GitLab Pages are
served under. You can call it by using the predefined
variable `$CI_PAGES_DOMAIN` in your script:

```yaml
pages:
  script:
    - ...
    - echo $CI_PAGES_DOMAIN
```

For GitLab.com users, the output will be `gitlab.io`. For your
private instance, the output will be whatever your sysadmin has
defined.

## Custom environment variables

When you need a specific custom environment variable, you can
[set it up in the UI](#create-a-custom-variable-in-the-ui), in [the API](../../api/project_level_variables.md),
or directly [in the `.gitlab-ci.yml` file](#create-a-custom-variable-in-gitlab-ciyml).

The variables are used by the Runner any time the pipeline runs.
You can also [override variable values manually for a specific pipeline](../pipelines/index.md#specifying-variables-when-running-manual-jobs).

There are two types of variables: **Variable** and **File**. You cannot set types in
the `.gitlab-ci.yml` file, but you can set them in the UI and API.

### Create a custom variable in `.gitlab-ci.yml`

To create a custom `env_var` variable in the [`.gitlab-ci.yml`](../yaml/README.md#variables) file,
define the variable/value pair under `variables`:

```yaml
variables:
  TEST: "HELLO WORLD"
```

You can then call its value in your script:

```yaml
  script:
    - echo "$TEST"
```

For more details, see [`.gitlab-ci.yml` defined variables](#gitlab-ciyml-defined-variables).

### Create a custom variable in the UI

From within the UI, you can add or update custom environment variables:

1. Go to your project's **Settings > CI/CD** and expand the **Variables** section.
1. Click the **Add Variable** button. In the **Add variable** modal, fill in the details:

    - **Key**: Must be one line, with no spaces, using only letters, numbers, or `_`.
    - **Value**: No limitations.
    - **Type**: `File` or `Variable`.
    - **Environment scope**: `All`, or specific environments.
    - **Protect variable** (Optional): If selected, the variable will only be available in pipelines that run on protected branches or tags.
    - **Mask variable** (Optional): If selected, the variable's **Value** will be masked in job logs. The variable fails to save if the value does not meet the [masking requirements](#masked-variable-requirements).

After a variable is created, you can update any of the details by clicking the **{pencil}** **Edit** button.

After you set a variable, call it from the `.gitlab-ci.yml` file:

```yaml
test_variable:
  stage: test
  script:
    - echo $CI_JOB_STAGE # calls a predefined variable
    - echo $TEST # calls a custom variable of type `env_var`
    - echo $GREETING # calls a custom variable of type `file` that contains the path to the temp file
    - cat $GREETING # the temp file itself contains the variable value
```

The output will be:

![Output custom variable](img/custom_variables_output.png)

### Custom environment variables of type Variable

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/46806) in GitLab 11.11.

For variables with the type **Variable**, the Runner creates an environment variable
that uses the key for the name and the value for the value.

There are [some predefined variables](#custom-variables-validated-by-gitlab) of this type,
which may be further validated. They appear when you add or update a variable in the UI.

### Custom environment variables of type File

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/46806) in GitLab 11.11.

For variables with the type **File**, the Runner creates an environment variable that uses the key for the name.
For the value, the Runner writes the variable value to a temporary file and uses this path.

You can use tools like [the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
and [`kubectl`](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#the-kubeconfig-environment-variable)
to customize your configuration by using **File** type variables.

In the past, a common pattern was to read the value of a CI variable, save it in a file, and then
use the newly created file in your script:

```shell
# Read certificate stored in $KUBE_CA_PEM variable and save it in a new file
echo "$KUBE_CA_PEM" > "$(pwd)/kube.ca.pem"
# Pass the newly created file to kubectl
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$(pwd)/kube.ca.pem"
```

Instead of this, you can use a **File** type variable. For example, if you have the following variables:

- A variable of type **Variable**: `KUBE_URL` with the value `https://example.com`.
- A variable of type **File**: `KUBE_CA_PEM` with a certificate as the value.

You can call them from `.gitlab-ci.yml`, like this:

```shell
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$KUBE_CA_PEM"
```

### Mask a custom variable

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/13784) in GitLab 11.10

Variables can be masked so that the value of the variable will be hidden in job logs.

To mask a variable:

1. Go to **Settings > CI/CD**.
1. Expand the **Variables** section.
1. Next to the variable you want to protect, click **Edit**.
1. Select the **Mask variable** check box.
1. Click **Update variable**.

#### Masked variable requirements

The value of the variable must:

- Be in a single line.
- Be at least 8 characters long.
- Not be a predefined or custom environment variable.
- Consist only of characters from the Base64 alphabet (RFC4648).
  [In GitLab 12.2](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/63043)
  and newer, `@` and `:` are also valid values.

You can't mask variables that don't meet these requirements.

### Protect a custom variable

> Introduced in GitLab 9.3.

Variables can be protected. When a variable is
protected, it is securely passed to pipelines running on
[protected branches](../../user/project/protected_branches.md) or [protected tags](../../user/project/protected_tags.md) only. The other pipelines do not get
the protected variable.

To protect a variable:

1. Go to **Settings > CI/CD**.
1. Expand the **Variables** section.
1. Next to the variable you want to protect, click **Edit**.
1. Select the **Protect variable** check box.
1. Click **Update variable**.

The variable is available for all subsequent pipelines.

### Custom variables validated by GitLab

Some variables are listed in the UI so you can choose them more quickly.
GitLab validates the values of these variables to ensure they are in the correct format.

| Variable                | Allowed Values                                     | Introduced in |
|-------------------------|----------------------------------------------------|---------------|
| `AWS_ACCESS_KEY_ID`     | 20 characters: letters, digits                     | 12.10         |
| `AWS_DEFAULT_REGION`    | Any                                                | 12.10         |
| `AWS_SECRET_ACCESS_KEY` | 40 characters: letters, digits, special characters | 12.10         |

NOTE: **Note:**
When you store credentials, there are security implications. If you are using AWS keys,
for example, follow their [best practices](https://docs.aws.amazon.com/general/latest/gr/aws-access-keys-best-practices.html).

## Syntax of environment variables in job scripts

All variables are set as environment variables in the build environment, and
they are accessible with normal methods that are used to access such variables.
In most cases `bash` or `sh` is used to execute the job script.

To access environment variables, use the syntax for your Runner's [shell](https://docs.gitlab.com/runner/executors/).

| Shell                | Usage                                    |
|----------------------|------------------------------------------|
| bash/sh              | `$variable`                              |
| PowerShell           | `$env:variable` (primary) or `$variable` |
| Windows Batch        | `%variable%`                             |

### Bash

To access environment variables in **bash**, prefix the variable name with (`$`):

```yaml
job_name:
  script:
    - echo $CI_JOB_ID
```

### PowerShell

To access environment variables in a **Windows PowerShell** environment, prefix
the variable name with (`$env:`). For environment variables set by GitLab CI, including those set by [`variables`](https://gitlab.com/gitlab-org/gitlab/blob/master/doc/ci/yaml/README.md#variables)
parameter, they can also be accessed by prefixing the variable name with (`$`)
as of [GitLab Runner 1.0.0](https://gitlab.com/gitlab-org/gitlab-runner/-/commit/abc44bb158008cd3a49c0d8173717c38dadb29ae#47afd7e8f12afdb8f0246262488f24e6dd071a22).
System set environment variables however must be accessed using (`$env:`).

```yaml
job_name:
  script:
    - echo $env:CI_JOB_ID
    - echo $CI_JOB_ID
    - echo $env:PATH
```

In [some cases](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/4115#note_157692820)
environment variables may need to be surrounded by quotes to expand properly:

```yaml
job_name:
  script:
    - D:\\qislsf\\apache-ant-1.10.5\\bin\\ant.bat "-DsosposDailyUsr=$env:SOSPOS_DAILY_USR" portal_test
```

### Windows Batch

To access environment variables in **Windows Batch**, surround the variable
with (`%`):

```yaml
job_name:
  script:
    - echo %CI_JOB_ID%
```

### List all environment variables

You can also list all environment variables with the `export` command in Bash
or `dir env:` command in PowerShell.
Be aware that this will also expose the values of all the variables
you set, in the job log:

```yaml
job_name:
  script:
    - export
    # - 'dir env:' # use this for PowerShell
```

Example values:

```shell
export CI_JOB_ID="50"
export CI_COMMIT_SHA="1ecfd275763eff1d6b4844ea3168962458c9f27a"
export CI_COMMIT_SHORT_SHA="1ecfd275"
export CI_COMMIT_REF_NAME="master"
export CI_REPOSITORY_URL="https://gitlab-ci-token:abcde-1234ABCD5678ef@example.com/gitlab-org/gitlab-foss.git"
export CI_COMMIT_TAG="1.0.0"
export CI_JOB_NAME="spec:other"
export CI_JOB_STAGE="test"
export CI_JOB_MANUAL="true"
export CI_JOB_TRIGGERED="true"
export CI_JOB_TOKEN="abcde-1234ABCD5678ef"
export CI_PIPELINE_ID="1000"
export CI_PIPELINE_IID="10"
export CI_PAGES_DOMAIN="gitlab.io"
export CI_PAGES_URL="https://gitlab-org.gitlab.io/gitlab-foss"
export CI_PROJECT_ID="34"
export CI_PROJECT_DIR="/builds/gitlab-org/gitlab-foss"
export CI_PROJECT_NAME="gitlab-foss"
export CI_PROJECT_TITLE="GitLab FOSS"
export CI_PROJECT_NAMESPACE="gitlab-org"
export CI_PROJECT_PATH="gitlab-org/gitlab-foss"
export CI_PROJECT_URL="https://example.com/gitlab-org/gitlab-foss"
export CI_REGISTRY="registry.example.com"
export CI_REGISTRY_IMAGE="registry.example.com/gitlab-org/gitlab-foss"
export CI_REGISTRY_USER="gitlab-ci-token"
export CI_REGISTRY_PASSWORD="longalfanumstring"
export CI_RUNNER_ID="10"
export CI_RUNNER_DESCRIPTION="my runner"
export CI_RUNNER_TAGS="docker, linux"
export CI_SERVER="yes"
export CI_SERVER_URL="https://example.com"
export CI_SERVER_HOST="example.com"
export CI_SERVER_PORT="443"
export CI_SERVER_PROTOCOL="https"
export CI_SERVER_NAME="GitLab"
export CI_SERVER_REVISION="70606bf"
export CI_SERVER_VERSION="8.9.0"
export CI_SERVER_VERSION_MAJOR="8"
export CI_SERVER_VERSION_MINOR="9"
export CI_SERVER_VERSION_PATCH="0"
export GITLAB_USER_EMAIL="user@example.com"
export GITLAB_USER_ID="42"
```

## `.gitlab-ci.yml` defined variables

NOTE: **Note:**
This feature requires GitLab Runner 0.5.0 or higher and GitLab 7.14 or higher.

You can add variables that are set in the build environment to `.gitlab-ci.yml`.
These variables are saved in the repository, and they
are meant to store non-sensitive project configuration, like `RAILS_ENV` or
`DATABASE_URL`.

For example, if you set the variable below globally (not inside a job), it will
be used in all executed commands and scripts:

```yaml
variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
```

The YAML-defined variables are also set to all created
[service containers](../docker/using_docker_images.md), so that you can fine
tune them.

Variables can be defined at a global level, but also at a job level. To turn off
global defined variables in your job, define an empty hash:

```yaml
job_name:
  variables: {}
```

You are able to use other variables inside your variable definition (or escape them with `$$`):

```yaml
variables:
  LS_CMD: 'ls $FLAGS $$TMP_DIR'
  FLAGS: '-al'
script:
  - 'eval $LS_CMD'  # will execute 'ls -al $TMP_DIR'
```

## Group-level environment variables

> Introduced in GitLab 9.4.

You can define per-project or per-group variables
that are set in the pipeline environment. Group-level variables are stored out of
the repository (not in `.gitlab-ci.yml`) and are securely passed to GitLab Runner,
which makes them available during a pipeline run. For Premium users who do **not** use an external key store or who use GitLab's [integration with HashiCorp Vault](../examples/authenticating-with-hashicorp-vault/index.md), we recommend using group environment variables to store secrets like passwords, SSH keys, and credentials.

Group-level variables can be added by:

1. Navigating to your group's **Settings > CI/CD** page.
1. Inputting variable types, keys, and values in the **Variables** section.
   Any variables of [subgroups](../../user/group/subgroups/index.md) will be inherited recursively.

Once you set them, they will be available for all subsequent pipelines. Any group-level user defined variables can be viewed in projects by:

1. Navigating to the project's **Settings > CI/CD** page.
1. Expanding the **Variables** section.

![CI/CD settings - inherited variables](img/inherited_group_variables_v12_5.png)

## Instance-level CI/CD environment variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/14108) in GitLab 13.0.

Instance variables are useful for no longer needing to manually enter the same credentials repeatedly for all your projects. Instance-level variables are available to all projects and groups on the instance.

NOTE: **Note:**
The maximum number of instance-level variables is [planned to be 25](https://gitlab.com/gitlab-org/gitlab/-/issues/216097).

You can define instance-level variables via the UI or [API](../../api/instance_level_ci_variables.md).

To add an instance-level variable:

1. Navigate to your admin area's **Settings > CI/CD** and expand the **Variables** section.
1. Click the **Add variable** button, and fill in the details:

    - **Key**: Must be one line, using only letters, numbers, or `_` (underscore), with no spaces.
    - **Value**: 700 characters allowed.
    - **Type**: `File` or `Variable`.
    - **Protect variable** (Optional): If selected, the variable will only be available in pipelines that run on protected branches or tags.
    - **Mask variable** (Optional): If selected, the variable's **Value** will not be shown in job logs. The variable will not be saved if the value does not meet the [masking requirements](#masked-variable-requirements).

After a variable is created, you can update any of the details by clicking the **{pencil}** **Edit** button.

### Enable or disable UI interface for instance-level CI/CD variables

The UI interface for Instance-level CI/CD variables is under development but ready for production use.
It is deployed behind a feature flag that is **enabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md) can opt to disable it for your instance.

NOTE: **Note:**
This feature will not work if the [instance-level CI/CD variables API feature flag is disabled](../../api/instance_level_ci_variables.md#enable-or-disable-instance-level-cicd-variables-core-only).

To disable it:

```ruby
Feature.disable(:instance_variables_ui)
```

To enable it:

```ruby
Feature.enable(:instance_variables_ui)
```

## Inherit environment variables

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/22638) in GitLab 13.0.
> - It's deployed behind a feature flag (`ci_dependency_variables`), disabled by default.

You can inherit environment variables from dependent jobs.

This feature makes use of the [`artifacts:reports:dotenv`](../pipelines/job_artifacts.md#artifactsreportsdotenv) report feature.

Example with [`dependencies`](../yaml/README.md#dependencies) keyword.

```yaml
build:
  stage: build
  script:
    - echo "BUILD_VERSION=hello" >> build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  stage: deploy
  script:
    - echo $BUILD_VERSION # => hello
  dependencies:
    - build
```

Example with the [`needs`](../yaml/README.md#artifact-downloads-with-needs) keyword:

```yaml
build:
  stage: build
  script:
    - echo "BUILD_VERSION=hello" >> build.env
  artifacts:
    reports:
      dotenv: build.env

deploy:
  stage: deploy
  script:
    - echo $BUILD_VERSION # => hello
  needs:
    - job: build
      artifacts: true
```

### Enable inherited environment variables **(CORE ONLY)**

The Inherited Environment Variables feature is under development and not ready for production use. It is
deployed behind a feature flag that is **disabled by default**.
[GitLab administrators with access to the GitLab Rails console](../../administration/feature_flags.md)
can enable it for your instance.

To enable it:

```ruby
Feature.enable(:ci_dependency_variables)
```

To disable it:

```ruby
Feature.disable(:ci_dependency_variables)
```

## Priority of environment variables

Variables of different types can take precedence over other
variables, depending on where they are defined.

The order of precedence for variables is (from highest to lowest):

1. [Trigger variables](../triggers/README.md#making-use-of-trigger-variables), [scheduled pipeline variables](../pipelines/schedules.md#using-variables),
   and [manual pipeline run variables](#override-a-variable-by-manually-running-a-pipeline).
1. Project-level [variables](#custom-environment-variables) or [protected variables](#protect-a-custom-variable).
1. Group-level [variables](#group-level-environment-variables) or [protected variables](#protect-a-custom-variable).
1. [Inherited environment variables](#inherit-environment-variables).
1. YAML-defined [job-level variables](../yaml/README.md#variables).
1. YAML-defined [global variables](../yaml/README.md#variables).
1. [Deployment variables](#deployment-environment-variables).
1. [Predefined environment variables](predefined_variables.md).

For example, if you define:

- `API_TOKEN=secure` as a project variable.
- `API_TOKEN=yaml` in your `.gitlab-ci.yml`.

`API_TOKEN` will take the value `secure` as the project
variables take precedence over those defined in `.gitlab-ci.yml`.

## Unsupported variables

Variable names are limited by the underlying shell used to execute scripts (see [available shells](https://docs.gitlab.com/runner/shells/index.html).
Each shell has its own unique set of reserved variable names.
You will also want to keep in mind the [scope of environment variables](where_variables_can_be_used.md) to ensure a variable is defined in the scope
in which you wish to use it.

## Where variables can be used

Click [here](where_variables_can_be_used.md) for a section that describes where and how the different types of variables can be used.

## Advanced use

### Limit the environment scopes of environment variables

You can limit the environment scope of a variable by
[defining which environments](../environments/index.md) it can be available for.

To learn more about scoping environments, see [Scoping environments with specs](../environments/index.md#scoping-environments-with-specs).

### Deployment environment variables

> Introduced in GitLab 8.15.

[Integrations](../../user/project/integrations/overview.md) that are
responsible for deployment configuration may define their own variables that
are set in the build environment. These variables are only defined for
[deployment jobs](../environments/index.md). Please consult the documentation of
the integrations that you are using to learn which variables they define.

An example integration that defines deployment variables is the
[Kubernetes integration](../../user/project/clusters/index.md#deployment-variables).

### Auto DevOps environment variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/49056) in GitLab 11.7.

You can configure [Auto DevOps](../../topics/autodevops/index.md) to
pass CI variables to the running application by prefixing the key of the
variable with `K8S_SECRET_`.

These [prefixed
variables](../../topics/autodevops/customize.md#application-secret-variables) will
then be available as environment variables on the running application
container.

CAUTION: **Caution:**
Variables with multi-line values are not currently supported due to
limitations with the current Auto DevOps scripting environment.

### Override a variable by manually running a pipeline

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/44059) in GitLab 10.8.

You can override the value of a current variable by
[running a pipeline manually](../pipelines/index.md#run-a-pipeline-manually).

For instance, suppose you added a custom variable named `$TEST`
and you want to override it in a manual pipeline.

Navigate to your project's **CI/CD > Pipelines** and click **Run pipeline**.
Choose the branch you want to run the pipeline for, then add a variable and its value in the UI:

![Override variable value](img/override_variable_manual_pipeline.png)

The Runner overrides the value previously set and uses the custom
value for this specific pipeline.

![Manually overridden variable output](img/override_value_via_manual_pipeline_output.png)

## Environment variables expressions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/37397) in GitLab 10.7 for [the `only` and `except` CI keywords](../yaml/README.md#onlyexcept-advanced)
> - [Expanded](https://gitlab.com/gitlab-org/gitlab/-/issues/27863) in GitLab 12.3 with [the `rules` keyword](../yaml/README.md#rules)

Use variable expressions to limit which jobs are created
within a pipeline after changes are pushed to GitLab.

In `.gitlab-ci.yml`, variable expressions work with both:

- [`rules`](../yaml/README.md#rules), which is the recommended approach, and
- [`only` and `except`](../yaml/README.md#onlyexcept-basic), which are candidates for deprecation.

This is particularly useful in combination with variables and triggered
pipeline variables.

```yaml
deploy:
  script: cap staging deploy
  environment: staging
  only:
    variables:
      - $RELEASE == "staging"
      - $STAGING
```

Each expression provided is evaluated before a pipeline is created.

If any of the conditions in `variables` evaluates to true when using `only`,
a new job is created. If any of the expressions evaluates to true
when `except` is being used, a job is not created.

This follows the usual rules for [`only` / `except` policies](../yaml/README.md#onlyexcept-advanced).

### Syntax of environment variable expressions

Below you can find supported syntax reference:

1. Equality matching using a string

   Examples:

   - `$VARIABLE == "some value"`
   - `$VARIABLE != "some value"` (introduced in GitLab 11.11)

   You can use equality operator `==` or `!=` to compare a variable content to a
   string. We support both, double quotes and single quotes to define a string
   value, so both `$VARIABLE == "some value"` and `$VARIABLE == 'some value'`
   are supported. `"some value" == $VARIABLE` is correct too.

1. Checking for an undefined value

   Examples:

   - `$VARIABLE == null`
   - `$VARIABLE != null` (introduced in GitLab 11.11)

   It sometimes happens that you want to check whether a variable is defined
   or not. To do that, you can compare a variable to `null` keyword, like
   `$VARIABLE == null`. This expression evaluates to true if
   variable is not defined when `==` is used, or to false if `!=` is used.

1. Checking for an empty variable

   Examples:

   - `$VARIABLE == ""`
   - `$VARIABLE != ""` (introduced in GitLab 11.11)

   If you want to check whether a variable is defined, but is empty, you can
   simply compare it against an empty string, like `$VAR == ''` or non-empty
   string `$VARIABLE != ""`.

1. Comparing two variables

   Examples:

   - `$VARIABLE_1 == $VARIABLE_2`
   - `$VARIABLE_1 != $VARIABLE_2` (introduced in GitLab 11.11)

   It is possible to compare two variables. This is going to compare values
   of these variables.

1. Variable presence check

   Example: `$STAGING`

   If you only want to create a job when there is some variable present,
   which means that it is defined and non-empty, you can simply use
   variable name as an expression, like `$STAGING`. If `$STAGING` variable
   is defined, and is non empty, expression will evaluate to truth.
   `$STAGING` value needs to be a string, with length higher than zero.
   Variable that contains only whitespace characters is not an empty variable.

1. Pattern matching (introduced in GitLab 11.0)

   Examples:

   - `=~`: True if pattern is matched. Ex: `$VARIABLE =~ /^content.*/`
   - `!~`: True if pattern is not matched. Ex: `$VARIABLE_1 !~ /^content.*/` ([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/issues/61900) in GitLab 11.11)

   Variable pattern matching with regular expressions uses the
   [RE2 regular expression syntax](https://github.com/google/re2/wiki/Syntax).
   Expressions evaluate as `true` if:

   - Matches are found when using `=~`.
   - Matches are *not* found when using `!~`.

   Pattern matching is case-sensitive by default. Use `i` flag modifier, like
   `/pattern/i` to make a pattern case-insensitive.

1. Conjunction / Disjunction ([introduced](https://gitlab.com/gitlab-org/gitlab-foss/-/merge_requests/27925) in GitLab 12.0)

   Examples:

   - `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 == "something"`
   - `$VARIABLE1 =~ /^content.*/ && $VARIABLE2 =~ /thing$/ && $VARIABLE3`
   - `$VARIABLE1 =~ /^content.*/ || $VARIABLE2 =~ /thing$/ && $VARIABLE3`

   It is possible to join multiple conditions using `&&` or `||`. Any of the otherwise
   supported syntax may be used in a conjunctive or disjunctive statement.
   Precedence of operators follows the
   [Ruby 2.5 standard](https://ruby-doc.org/core-2.5.0/doc/syntax/precedence_rdoc.html),
   so `&&` is evaluated before `||`.

### Storing regular expressions in variables

It is possible to store a regular expression in a variable, to be used for pattern matching:

```yaml
variables:
  STAGINGRELS: '/staging0|staging1/'

deploy_staging:
  script: do.sh deploy staging
  environment: staging
  rules:
    - if: '$RELEASE =~ $STAGINGRELS'
```

NOTE: **Note:**
The available regular expression syntax is limited. See [related issue](https://gitlab.com/gitlab-org/gitlab/-/issues/35438)
for more details.

If needed, you can use a test pipeline to determine whether a regular expression will
work in a variable. The example below tests the `^mast.*` regular expression directly,
as well as from within a variable:

```yaml
variables:
  MYSTRING: 'master'
  MYREGEX: '/^mast.*/'

testdirect:
  script: /bin/true
  rules:
    - if: '$MYSTRING =~ /^mast.*/'

testvariable:
  script: /bin/true
  rules:
    - if: '$MYSTRING =~ $MYREGEX'
```

## Debug logging

> Introduced in GitLab Runner 1.7.

CAUTION: **Warning:**
Enabling debug tracing can have severe security implications. The
output **will** contain the content of all your variables and any other
secrets! The output **will** be uploaded to the GitLab server and made visible
in job logs!

By default, GitLab Runner hides most of the details of what it is doing when
processing a job. This behavior keeps job logs short, and prevents secrets
from being leaked into the log unless your script writes them to the screen.

If a job isn't working as expected, this can make the problem difficult to
investigate; in these cases, you can enable debug tracing in `.gitlab-ci.yml`.
Available on GitLab Runner v1.7+, this feature enables the shell's execution
log, resulting in a verbose job log listing all commands that were run,
variables that were set, and so on.

Before enabling this, you should ensure jobs are visible to
[team members only](../../user/permissions.md#project-features). You should
also [erase](../pipelines/index.md#view-jobs-in-a-pipeline) all generated job logs
before making them visible again.

To enable debug logs (traces), set the `CI_DEBUG_TRACE` variable to `true`:

```yaml
job_name:
  variables:
    CI_DEBUG_TRACE: "true"
```

Example truncated output with `CI_DEBUG_TRACE` set to `true`:

```shell
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
++ export CI_BUILD_ID=379424655
++ CI_BUILD_ID=379424655
++ export CI_BUILD_TOKEN=[MASKED]
++ CI_BUILD_TOKEN=[MASKED]
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
++ export CI_BUILD_NAME=debug_trace
++ CI_BUILD_NAME=debug_trace
++ export CI_BUILD_STAGE=test
++ CI_BUILD_STAGE=test
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
++ export CI_SERVER_PROTOCOL=https
++ CI_SERVER_PROTOCOL=https
++ export CI_SERVER_NAME=GitLab
++ CI_SERVER_NAME=GitLab
++ export CI_SERVER_VERSION=12.6.0-pre
++ CI_SERVER_VERSION=12.6.0-pre
++ export CI_SERVER_VERSION_MAJOR=12
++ CI_SERVER_VERSION_MAJOR=12
++ export CI_SERVER_VERSION_MINOR=6
++ CI_SERVER_VERSION_MINOR=6
++ export CI_SERVER_VERSION_PATCH=0
++ CI_SERVER_VERSION_PATCH=0
++ export CI_SERVER_REVISION=f4cc00ae823
++ CI_SERVER_REVISION=f4cc00ae823
++ export GITLAB_FEATURES=audit_events,burndown_charts,code_owners,contribution_analytics,description_diffs,elastic_search,group_bulk_edit,group_burndown_charts,group_webhooks,issuable_default_templates,issue_weights,jenkins_integration,ldap_group_sync,member_lock,merge_request_approvers,multiple_issue_assignees,multiple_ldap_servers,multiple_merge_request_assignees,protected_refs_for_users,push_rules,related_issues,repository_mirrors,repository_size_limit,scoped_issue_board,usage_quotas,visual_review_app,wip_limits,adjourned_deletion_for_projects_and_groups,admin_audit_log,auditor_user,batch_comments,blocking_merge_requests,board_assignee_lists,board_milestone_lists,ci_cd_projects,cluster_deployments,code_analytics,code_owner_approval_required,commit_committer_check,cross_project_pipelines,custom_file_templates,custom_file_templates_for_namespace,custom_project_templates,custom_prometheus_metrics,cycle_analytics_for_groups,db_load_balancing,default_project_deletion_protection,dependency_proxy,deploy_board,design_management,email_additional_text,extended_audit_events,external_authorization_service_api_management,feature_flags,file_locks,geo,github_project_service_integration,group_allowed_email_domains,group_project_templates,group_saml,issues_analytics,jira_dev_panel_integration,ldap_group_sync_filter,merge_pipelines,merge_request_performance_metrics,merge_trains,metrics_reports,multiple_approval_rules,multiple_clusters,multiple_group_issue_boards,object_storage,operations_dashboard,packages,productivity_analytics,project_aliases,protected_environments,reject_unsigned_commits,required_ci_templates,scoped_labels,service_desk,smartcard_auth,group_timelogs,type_of_work_analytics,unprotection_restrictions,ci_project_subscriptions,cluster_health,container_scanning,dast,dependency_scanning,epics,group_ip_restriction,incident_management,insights,license_management,personal_access_token_expiration_policy,pod_logs,prometheus_alerts,pseudonymizer,report_approver_rules,sast,security_dashboard,tracing,web_ide_terminal
++ GITLAB_FEATURES=audit_events,burndown_charts,code_owners,contribution_analytics,description_diffs,elastic_search,group_bulk_edit,group_burndown_charts,group_webhooks,issuable_default_templates,issue_weights,jenkins_integration,ldap_group_sync,member_lock,merge_request_approvers,multiple_issue_assignees,multiple_ldap_servers,multiple_merge_request_assignees,protected_refs_for_users,push_rules,related_issues,repository_mirrors,repository_size_limit,scoped_issue_board,usage_quotas,visual_review_app,wip_limits,adjourned_deletion_for_projects_and_groups,admin_audit_log,auditor_user,batch_comments,blocking_merge_requests,board_assignee_lists,board_milestone_lists,ci_cd_projects,cluster_deployments,code_analytics,code_owner_approval_required,commit_committer_check,cross_project_pipelines,custom_file_templates,custom_file_templates_for_namespace,custom_project_templates,custom_prometheus_metrics,cycle_analytics_for_groups,db_load_balancing,default_project_deletion_protection,dependency_proxy,deploy_board,design_management,email_additional_text,extended_audit_events,external_authorization_service_api_management,feature_flags,file_locks,geo,github_project_service_integration,group_allowed_email_domains,group_project_templates,group_saml,issues_analytics,jira_dev_panel_integration,ldap_group_sync_filter,merge_pipelines,merge_request_performance_metrics,merge_trains,metrics_reports,multiple_approval_rules,multiple_clusters,multiple_group_issue_boards,object_storage,operations_dashboard,packages,productivity_analytics,project_aliases,protected_environments,reject_unsigned_commits,required_ci_templates,scoped_labels,service_desk,smartcard_auth,group_timelogs,type_of_work_analytics,unprotection_restrictions,ci_project_subscriptions,cluster_health,container_scanning,dast,dependency_scanning,epics,group_ip_restriction,incident_management,insights,license_management,personal_access_token_expiration_policy,pod_logs,prometheus_alerts,pseudonymizer,report_approver_rules,sast,security_dashboard,tracing,web_ide_terminal
++ export CI_PROJECT_ID=17893
++ CI_PROJECT_ID=17893
++ export CI_PROJECT_NAME=ci-debug-trace
++ CI_PROJECT_NAME=ci-debug-trace
++ export CI_PROJECT_TITLE='GitLab FOSS'
++ CI_PROJECT_TITLE='GitLab FOSS'
++ export CI_PROJECT_PATH=gitlab-examples/ci-debug-trace
++ CI_PROJECT_PATH=gitlab-examples/ci-debug-trace
++ export CI_PROJECT_PATH_SLUG=gitlab-examples-ci-debug-trace
++ CI_PROJECT_PATH_SLUG=gitlab-examples-ci-debug-trace
++ export CI_PROJECT_NAMESPACE=gitlab-examples
++ CI_PROJECT_NAMESPACE=gitlab-examples
++ export CI_PROJECT_URL=https://gitlab.com/gitlab-examples/ci-debug-trace
++ CI_PROJECT_URL=https://gitlab.com/gitlab-examples/ci-debug-trace
++ export CI_PROJECT_VISIBILITY=public
++ CI_PROJECT_VISIBILITY=public
++ export CI_PROJECT_REPOSITORY_LANGUAGES=
++ CI_PROJECT_REPOSITORY_LANGUAGES=
++ export CI_DEFAULT_BRANCH=master
++ CI_DEFAULT_BRANCH=master
++ export CI_REGISTRY=registry.gitlab.com
++ CI_REGISTRY=registry.gitlab.com
++ export CI_API_V4_URL=https://gitlab.com/api/v4
++ CI_API_V4_URL=https://gitlab.com/api/v4
++ export CI_PIPELINE_IID=123
++ CI_PIPELINE_IID=123
++ export CI_PIPELINE_SOURCE=web
++ CI_PIPELINE_SOURCE=web
++ export CI_CONFIG_PATH=.gitlab-ci.yml
++ CI_CONFIG_PATH=.gitlab-ci.yml
++ export CI_COMMIT_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_COMMIT_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_COMMIT_SHORT_SHA=dd648b2e
++ CI_COMMIT_SHORT_SHA=dd648b2e
++ export CI_COMMIT_BEFORE_SHA=0000000000000000000000000000000000000000
++ CI_COMMIT_BEFORE_SHA=0000000000000000000000000000000000000000
++ export CI_COMMIT_REF_NAME=master
++ CI_COMMIT_REF_NAME=master
++ export CI_COMMIT_REF_SLUG=master
++ CI_COMMIT_REF_SLUG=master
++ export CI_COMMIT_MESSAGE=s/CI/Runner
++ CI_COMMIT_MESSAGE=s/CI/Runner
++ export CI_COMMIT_TITLE=s/CI/Runner
++ CI_COMMIT_TITLE=s/CI/Runner
++ export CI_COMMIT_DESCRIPTION=
++ CI_COMMIT_DESCRIPTION=
++ export CI_COMMIT_REF_PROTECTED=true
++ CI_COMMIT_REF_PROTECTED=true
++ export CI_BUILD_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_BUILD_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_BUILD_BEFORE_SHA=0000000000000000000000000000000000000000
++ CI_BUILD_BEFORE_SHA=0000000000000000000000000000000000000000
++ export CI_BUILD_REF_NAME=master
++ CI_BUILD_REF_NAME=master
++ export CI_BUILD_REF_SLUG=master
++ CI_BUILD_REF_SLUG=master
++ export CI_RUNNER_ID=1337
++ CI_RUNNER_ID=1337
++ export CI_RUNNER_DESCRIPTION=shared-runners-manager-4.gitlab.com
++ CI_RUNNER_DESCRIPTION=shared-runners-manager-4.gitlab.com
++ export 'CI_RUNNER_TAGS=gce, east-c, shared, docker, linux, ruby, mysql, postgres, mongo, git-annex'
++ CI_RUNNER_TAGS='gce, east-c, shared, docker, linux, ruby, mysql, postgres, mongo, git-annex'
++ export CI_DEBUG_TRACE=true
++ CI_DEBUG_TRACE=true
++ export GITLAB_USER_ID=42
++ GITLAB_USER_ID=42
++ export GITLAB_USER_EMAIL=user@example.com
++ GITLAB_USER_EMAIL=user@example.com
++ export GITLAB_USER_LOGIN=root
++ GITLAB_USER_LOGIN=root
++ export 'GITLAB_USER_NAME=User'
++ GITLAB_USER_NAME='User'
++ export CI_DISPOSABLE_ENVIRONMENT=true
++ CI_DISPOSABLE_ENVIRONMENT=true
++ export CI_RUNNER_VERSION=12.5.0
++ CI_RUNNER_VERSION=12.5.0
++ export CI_RUNNER_REVISION=577f813d
++ CI_RUNNER_REVISION=577f813d
++ export CI_RUNNER_EXECUTABLE_ARCH=linux/amd64
++ CI_RUNNER_EXECUTABLE_ARCH=linux/amd64
++ export VERY_SECURE_VARIABLE=imaverysecurevariable
++ VERY_SECURE_VARIABLE=imaverysecurevariable

...
```

## Video walkthrough of a working example

The [Managing the Complex Configuration Data Management Monster Using GitLab](https://www.youtube.com/watch?v=v4ZOJ96hAck) video is a walkthrough of the [Complex Config Data Monorepo](https://gitlab.com/guided-explorations/config-data-top-scope/config-data-subscope/config-data-monorepo) working example project. It explains how multiple levels of group CI/CD variables can be combined with environment-scoped project variables for complex configuration of application builds or deployments.

The example can be copied to your own group or instance for testing. More details
on what other GitLab CI patterns are demonstrated are available at the project page.
