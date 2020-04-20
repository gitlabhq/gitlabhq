---
type: reference
---

# GitLab CI/CD environment variables

After a brief overview of the use of environment
variables, this document teaches you how to use GitLab CI/CD's
variables, presents the full reference for predefined variables,
and dives into more advanced applications.

## Overview

An environment variable is a dynamic-named value that can
affect the way running processes will behave on an operating
system.

They are part of the environment in which a process runs.
For example, a running process can query the value of the
`TEMP` environment variable to discover a suitable location
to store temporary files, or to define a `URL` for a database
that can be reused in different scripts.

Variables are useful for customizing your jobs in GitLab
CI/CD's pipelines. Using variables means no hardcoded values.

### Predefined environment variables

GitLab CI/CD has a [default set of predefined variables](predefined_variables.md)
which can be used without any specification needed.
You can call issues numbers, user names, branch names,
pipeline and commit IDs, and much more.

Predefined environment variables are the ones that GitLab
provides out of the box for the local environment of the Runner.

GitLab reads the `.gitlab-ci.yml` file, sends the information
to the Runner (which runs the script commands), under which
the variables are exposed.

For example, two jobs under the same pipeline can share the same
`CI_PIPELINE_ID` variable, but each one has its own `CI_JOB_ID`
variable.

NOTE: **Note:**
Find here the full [**predefined variables reference table**](predefined_variables.md).

### Custom environment variables

When your use case requires a specific variable, you can
[set them up easily from the UI](#creating-a-custom-environment-variable)
or directly in the `.gitlab-ci.yml` file and reuse them as you wish.

That can be very powerful as it can be used for scripting without
the need to specify the value itself.

#### Types of variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/46806) in GitLab 11.11.

There are two types of variables supported by GitLab:

- [Variable type](#variable-type): The Runner will create an environment variable named the same as the
  variable key and set its value to the variable value.
- [File type](#file-type): The Runner will write the variable value to a temporary file and set the
  path to this file as the value of an environment variable, named the same as the variable key.

##### Variable type

Many tools (like [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)
and [kubectl](https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/#the-kubeconfig-environment-variable))
provide the ability to customise configuration using files by either providing the
file path as a command line argument or an environment variable. In the past, the
common pattern was to read the value of a CI variable, save it in a file, and then
use the newly created file in your script:

```shell
# Read certificate stored in $KUBE_CA_PEM variable and save it in a new file
echo "$KUBE_CA_PEM" > "$(pwd)/kube.ca.pem"
# Pass the newly created file to kubectl
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$(pwd)/kube.ca.pem"
```

There are [some predefined variables](#custom-variables-validated-by-gitlab) of this type, which may be further validated. They will appear when you add or update a variable.

##### File type

The example above can now be simplified by creating a "File" type variable, and using
it directly. For example, let's say we have the following variables:

![CI/CD settings - variable types usage example](img/variable_types_usage_example.png)

We can then call them from `.gitlab-ci.yml` like this:

```shell
kubectl config set-cluster e2e --server="$KUBE_URL" --certificate-authority="$KUBE_CA_PEM"
```

Variable types can be set via the [UI](#via-the-ui) or the [API](../../api/project_level_variables.md#create-variable), but not in `.gitlab-ci.yml`.

#### Masked variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/13784) in GitLab 11.10

Variables can be created as masked variables.
This means that the value of the variable will be hidden in job logs,
though it must match certain requirements to do so:

- The value must be in a single line.
- The value must only consist of characters from the Base64 alphabet (RFC4648).

  [In GitLab 12.2](https://gitlab.com/gitlab-org/gitlab-foss/issues/63043)
  and newer, `@` and `:` are also valid values.
- The value must be at least 8 characters long.
- The value must not use variables.

If the value does not meet the requirements above, then the CI variable will fail to save.
In order to save, either alter the value to meet the masking requirements
or disable **Masked** for the variable.

#### Custom variables validated by GitLab

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

## Getting started

To get started with environment variables in the scope of GitLab
CI/CD, let's go over a few examples.

### Using predefined environment variables

To get started, choose one of the existing
[predefined variables](predefined_variables.md)
to be output by the Runner. For example, let's say that you want
a given job you're running through your script to output the
stage that job is running for. In your `.gitlab-ci.yml` file,
call the variable from your script according to the [syntaxes](#syntax-of-environment-variables-in-job-scripts) available. To
output the job stage, use the predefined variable `CI_JOB_STAGE`:

```yaml
test_variable:
  stage: test
  script:
    - echo $CI_JOB_STAGE
```

For this case, the Runner will output the `stage` for the
job `test_variable`, which is `test`:

![Output `$CI_JOB_STAGE`](img/ci_job_stage_output_example.png)

As another example, let's say you're using your own GitLab
instance you want to know what domain your GitLab Pages are
served under. You can easily call it with the predefined
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

### Creating a custom environment variable

Assume you have something you want to repeat through your scripts
in GitLab CI/CD's configuration file. To keep this example simple,
let's say you want to output `HELLO WORLD` for a `TEST` variable.

You can either set the variable directly in the `.gitlab-ci.yml`
file or through the UI.

NOTE: **Note:**
It is possible to [specify variables when running manual jobs](../pipelines/index.md#specifying-variables-when-running-manual-jobs).

#### Via `.gitlab-ci.yml`

To create a new custom `env_var` variable via [`.gitlab-ci.yml`](../yaml/README.md#variables), define their variable/value pair under
`variables`:

```yaml
variables:
  TEST: "HELLO WORLD"
```

For a deeper look into them, see [`.gitlab-ci.yml` defined variables](#gitlab-ciyml-defined-variables).

#### Via the UI

From within the UI, you can add or update custom environment variables:

1. Go to your project's **Settings > CI/CD** and expand the **Variables** section.
1. Click the **Add variable** button. In the **Add variable** modal, fill in the details:

    - **Key**: Must be one line, with no spaces, using only letters, numbers, `-` or `_`.
    - **Value**: No limitations.
    - **Type**: `File` or `Variable`.
    - **Environment scope**: `All`, or specific environments.
    - **Protect variable** (Optional): If selected, the variable will only be available in pipelines that run on protected branches or tags.
    - **Mask variable** (Optional): If selected, the variable's **Value** will be masked in job logs. The variable will fail to save if the value does not meet the [masking requirements](#masked-variables).

After a variable is created, you can update any of the details by clicking on the **{pencil}** **Edit** button.

Once you've set the variables, call them from the `.gitlab-ci.yml` file:

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

### Syntax of environment variables in job scripts

All variables are set as environment variables in the build environment, and
they are accessible with normal methods that are used to access such variables.
In most cases `bash` or `sh` is used to execute the job script.

To access environment variables, use the syntax for your Runner's [shell](https://docs.gitlab.com/runner/executors/).

| Shell                | Usage           |
|----------------------|-----------------|
| bash/sh              | `$variable`     |
| windows batch        | `%variable%`    |
| PowerShell           | `$env:variable` |

To access environment variables in bash, prefix the variable name with (`$`):

```yaml
job_name:
  script:
    - echo $CI_JOB_ID
```

To access environment variables in **Windows Batch**, surround the variable
with (`%`):

```yaml
job_name:
  script:
    - echo %CI_JOB_ID%
```

To access environment variables in a **Windows PowerShell** environment, prefix
the variable name with (`$env:`):

```yaml
job_name:
  script:
    - echo $env:CI_JOB_ID
```

You can also list all environment variables with the `export` command,
but be aware that this will also expose the values of all the variables
you set, in the job log:

```yaml
job_name:
  script:
    - export
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

### `.gitlab-ci.yml` defined variables

NOTE: **Note:**
This feature requires GitLab Runner 0.5.0 or higher and GitLab 7.14 or higher.

GitLab CI/CD allows you to add to `.gitlab-ci.yml` variables that are set in the
build environment. The variables are hence saved in the repository, and they
are meant to store non-sensitive project configuration. For example, `RAILS_ENV` or
`DATABASE_URL`.

For example, if you set the variable below globally (not inside a job), it will
be used in all executed commands and scripts:

```yaml
variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
```

The YAML-defined variables are also set to all created
[service containers](../docker/using_docker_images.md), thus allowing to fine
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

### Group-level environment variables

> Introduced in GitLab 9.4.

GitLab CI/CD allows you to define per-project or per-group variables
that are set in the pipeline environment. Group-level variables are stored out of
the repository (not in `.gitlab-ci.yml`) and are securely passed to GitLab Runner
making them available during a pipeline run. It's the **recommended method** to
use for storing things like passwords, SSH keys, and credentials.

Group-level variables can be added by:

1. Navigating to your group's **Settings > CI/CD** page.
1. Inputing variable types, keys, and values in the **Variables** section.
   Any variables of [subgroups](../../user/group/subgroups/index.md) will be inherited recursively.

Once you set them, they will be available for all subsequent pipelines. Any group-level user defined variables can be viewed in projects by:

1. Navigating to the project's **Settings > CI/CD** page.
1. Expanding the **Variables** section.

![CI/CD settings - inherited variables](img/inherited_group_variables_v12_5.png)

## Priority of environment variables

Variables of different types can take precedence over other
variables, depending on where they are defined.

The order of precedence for variables is (from highest to lowest):

1. [Trigger variables](../triggers/README.md#making-use-of-trigger-variables) or [scheduled pipeline variables](../pipelines/schedules.md#using-variables).
1. Project-level [variables](#creating-a-custom-environment-variable) or [protected variables](#protected-environment-variables).
1. Group-level [variables](#group-level-environment-variables) or [protected variables](#protected-environment-variables).
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

There are cases where some variables cannot be used in the context of a
`.gitlab-ci.yml` definition (for example under `script`). Read more about which variables are [not supported](where_variables_can_be_used.md).

## Where variables can be used

Click [here](where_variables_can_be_used.md) for a section that describes where and how the different types of variables can be used.

## Advanced use

### Protected environment variables

> Introduced in GitLab 9.3.

Variables can be protected. Whenever a variable is
protected, it would only be securely passed to pipelines running on the
[protected branches](../../user/project/protected_branches.md) or [protected tags](../../user/project/protected_tags.md). The other pipelines would not get any
protected variables.

Protected variables can be added by going to your project's
**Settings > CI/CD**, then finding the section called
**Variables**, and check "Protected".

Once you set them, they will be available for all subsequent pipelines.

### Limiting environment scopes of environment variables

You can limit the environment scope of a variable by
[defining which environments](../environments.md) it can be available for.

To learn more about scoping environments, see [Scoping environments with specs](../environments.md#scoping-environments-with-specs).

### Deployment environment variables

> Introduced in GitLab 8.15.

[Integrations](../../user/project/integrations/overview.md) that are
responsible for deployment configuration may define their own variables that
are set in the build environment. These variables are only defined for
[deployment jobs](../environments.md). Please consult the documentation of
the integrations that you are using to learn which variables they define.

An example integration that defines deployment variables is the
[Kubernetes integration](../../user/project/clusters/index.md#deployment-variables).

### Auto DevOps environment variables

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/49056) in GitLab 11.7.

You can configure [Auto DevOps](../../topics/autodevops/index.md) to
pass CI variables to the running application by prefixing the key of the
variable with `K8S_SECRET_`.

These [prefixed
variables](../../topics/autodevops/customize.md#application-secret-variables) will
then be available as environment variables on the running application
container.

CAUTION: **Caution:**
Variables with multiline values are not currently supported due to
limitations with the current Auto DevOps scripting environment.

### Environment variables triggered manually

> [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/44059) in GitLab 10.8.

[Manually triggered pipelines](../pipelines/index.md#run-a-pipeline-manually) allow you to override the value of a current variable.

For instance, suppose you added a
[custom variable `$TEST`](#creating-a-custom-environment-variable)
as exemplified above and you want to override it in a manual pipeline.
Navigate to your project's **CI/CD > Pipelines** and click **Run pipeline**.
Choose the branch you want to run the pipeline for, then add a new variable through the UI:

![Override variable value](img/override_variable_manual_pipeline.png)

The Runner will override the value previously set and use the custom
value you set for this specific pipeline:

![Manually overridden variable output](img/override_value_via_manual_pipeline_output.png)

## Environment variables expressions

> - [Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/37397) in GitLab 10.7 for [the `only` and `except` CI keywords](../yaml/README.md#onlyexcept-advanced)
> - [Expanded](https://gitlab.com/gitlab-org/gitlab/issues/27863) in GitLab 12.3 with [the `rules` keyword](../yaml/README.md#rules)

Variable expressions can be used to limit what jobs are going to be created
within a pipeline after pushing changes to GitLab.

In `.gitlab-ci.yml`, they work with both

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

Each expression provided is going to be evaluated before creating a pipeline.

If any of the conditions in `variables` evaluates to truth when using `only`,
a new job is going to be created. If any of the expressions evaluates to truth
when `except` is being used, a job is not going to be created.

This follows usual rules for [`only` / `except` policies](../yaml/README.md#onlyexcept-advanced).

### Supported syntax

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
   `$VARIABLE == null`. This expression is going to evaluate to truth if
   variable is not defined when `==` is used, or to falsey if `!=` is used.

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
   `$STAGING` value needs to a string, with length higher than zero.
   Variable that contains only whitespace characters is not an empty variable.

1. Pattern matching (introduced in GitLab 11.0)

   Examples:

   - `=~`: True if pattern is matched. Ex: `$VARIABLE =~ /^content.*/`
   - `!~`: True if pattern is not matched. Ex: `$VARIABLE_1 !~ /^content.*/` ([Introduced](https://gitlab.com/gitlab-org/gitlab-foss/issues/61900) in GitLab 11.11)

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
The available regular expression syntax is limited. See [related issue](https://gitlab.com/gitlab-org/gitlab/issues/35438)
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
variables that were set, etc.

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
