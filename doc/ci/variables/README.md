# GitLab CI/CD Variables

When receiving a job from GitLab CI, the [Runner] prepares the build environment.
It starts by setting a list of **predefined variables** (environment variables)
and a list of **user-defined variables**.

## Priority of variables

The variables can be overwritten and they take precedence over each other in
this order:

1. [Trigger variables][triggers] or [scheduled pipeline variables](../../user/project/pipelines/schedules.md#making-use-of-scheduled-pipeline-variables) (take precedence over all)
1. Project-level [secret variables](#secret-variables) or [protected secret variables](#protected-secret-variables)
1. Group-level [secret variables](#secret-variables) or [protected secret variables](#protected-secret-variables)
1. YAML-defined [job-level variables](../yaml/README.md#variables)
1. YAML-defined [global variables](../yaml/README.md#variables)
1. [Deployment variables](#deployment-variables)
1. [Predefined variables](#predefined-variables-environment-variables) (are the
   lowest in the chain)

For example, if you define `API_TOKEN=secure` as a secret variable and
`API_TOKEN=yaml` in your `.gitlab-ci.yml`, the `API_TOKEN` will take the value
`secure` as the secret variables are higher in the chain.

## Predefined variables (Environment variables)

Some of the predefined environment variables are available only if a minimum
version of [GitLab Runner][runner] is used. Consult the table below to find the
version of Runner required.

>**Note:**
Starting with GitLab 9.0, we have deprecated some variables. Read the
[9.0 Renaming](#9-0-renaming) section to find out their replacements. **You are
strongly advised to use the new variables as we will remove the old ones in
future GitLab releases.**

| Variable                        | GitLab | Runner | Description |
|-------------------------------- |--------|--------|-------------|
| **CI**                          | all    | 0.4    | Mark that job is executed in CI environment |
| **CI_COMMIT_REF_NAME**          | 9.0    | all    | The branch or tag name for which project is built |
| **CI_COMMIT_REF_SLUG**          | 9.0    | all    | `$CI_COMMIT_REF_NAME` lowercased, shortened to 63 bytes, and with everything except `0-9` and `a-z` replaced with `-`. No leading / trailing `-`. Use in URLs, host names and domain names. |
| **CI_COMMIT_SHA**               | 9.0    | all    | The commit revision for which project is built |
| **CI_COMMIT_TAG**               | 9.0    | 0.5    | The commit tag name. Present only when building tags. |
| **CI_CONFIG_PATH**              | 9.4    | 0.5    | The path to CI config file. Defaults to `.gitlab-ci.yml` |
| **CI_DEBUG_TRACE**              | all    | 1.7    | Whether [debug tracing](#debug-tracing) is enabled |
| **CI_DISPOSABLE_ENVIRONMENT**   | all    | 10.1   | Marks that the job is executed in a disposable environment (something that is created only for this job and disposed of/destroyed after the execution - all executors except `shell` and `ssh`). If the environment is disposable, it is set to true, otherwise it is not defined at all. |
| **CI_ENVIRONMENT_NAME**         | 8.15   | all    | The name of the environment for this job |
| **CI_ENVIRONMENT_SLUG**         | 8.15   | all    | A simplified version of the environment name, suitable for inclusion in DNS, URLs, Kubernetes labels, etc. |
| **CI_ENVIRONMENT_URL**          | 9.3    | all    | The URL of the environment for this job |
| **CI_JOB_ID**                   | 9.0    | all    | The unique id of the current job that GitLab CI uses internally |
| **CI_JOB_MANUAL**               | 8.12   | all    | The flag to indicate that job was manually started |
| **CI_JOB_NAME**                 | 9.0    | 0.5    | The name of the job as defined in `.gitlab-ci.yml` |
| **CI_JOB_STAGE**                | 9.0    | 0.5    | The name of the stage as defined in `.gitlab-ci.yml` |
| **CI_JOB_TOKEN**                | 9.0    | 1.2    | Token used for authenticating with the GitLab Container Registry |
| **CI_REPOSITORY_URL**           | 9.0    | all    | The URL to clone the Git repository |
| **CI_RUNNER_DESCRIPTION**       | 8.10   | 0.5    | The description of the runner as saved in GitLab |
| **CI_RUNNER_ID**                | 8.10   | 0.5    | The unique id of runner being used |
| **CI_RUNNER_TAGS**              | 8.10   | 0.5    | The defined runner tags |
| **CI_RUNNER_VERSION**           | all    | 10.6   | GitLab Runner version that is executing the current job |
| **CI_RUNNER_REVISION**          | all    | 10.6   | GitLab Runner revision that is executing the current job |
| **CI_RUNNER_EXECUTABLE_ARCH**   | all    | 10.6   | The OS/architecture of the GitLab Runner executable (note that this is not necessarily the same as the environment of the executor) |
| **CI_PIPELINE_ID**              | 8.10   | 0.5    | The unique id of the current pipeline that GitLab CI uses internally |
| **CI_PIPELINE_TRIGGERED**       | all    | all    | The flag to indicate that job was [triggered] |
| **CI_PIPELINE_SOURCE**          | 10.0   | all    | The source for this pipeline, one of: push, web, trigger, schedule, api, external. Pipelines created before 9.5 will have unknown as source |
| **CI_PROJECT_DIR**              | all    | all    | The full path where the repository is cloned and where the job is run |
| **CI_PROJECT_ID**               | all    | all    | The unique id of the current project that GitLab CI uses internally |
| **CI_PROJECT_NAME**             | 8.10   | 0.5    | The project name that is currently being built (actually it is project folder name) |
| **CI_PROJECT_NAMESPACE**        | 8.10   | 0.5    | The project namespace (username or groupname) that is currently being built |
| **CI_PROJECT_PATH**             | 8.10   | 0.5    | The namespace with project name |
| **CI_PROJECT_PATH_SLUG**        | 9.3    | all    | `$CI_PROJECT_PATH` lowercased and with everything except `0-9` and `a-z` replaced with `-`. Use in URLs and domain names. |
| **CI_PROJECT_URL**              | 8.10   | 0.5    | The HTTP address to access project |
| **CI_PROJECT_VISIBILITY**       | 10.3   | all    | The project visibility (internal, private, public) |
| **CI_REGISTRY**                 | 8.10   | 0.5    | If the Container Registry is enabled it returns the address of GitLab's Container Registry |
| **CI_REGISTRY_IMAGE**           | 8.10   | 0.5    | If the Container Registry is enabled for the project it returns the address of the registry tied to the specific project |
| **CI_REGISTRY_PASSWORD**        | 9.0    | all    | The password to use to push containers to the GitLab Container Registry |
| **CI_REGISTRY_USER**            | 9.0    | all    | The username to use to push containers to the GitLab Container Registry |
| **CI_SERVER**                   | all    | all    | Mark that job is executed in CI environment |
| **CI_SERVER_NAME**              | all    | all    | The name of CI server that is used to coordinate jobs |
| **CI_SERVER_REVISION**          | all    | all    | GitLab revision that is used to schedule jobs |
| **CI_SERVER_VERSION**           | all    | all    | GitLab version that is used to schedule jobs |
| **CI_SHARED_ENVIRONMENT**       | all    | 10.1   | Marks that the job is executed in a shared environment (something that is persisted across CI invocations like `shell` or `ssh` executor). If the environment is shared, it is set to true, otherwise it is not defined at all. |
| **ARTIFACT_DOWNLOAD_ATTEMPTS**  | 8.15   | 1.9    | Number of attempts to download artifacts running a job |
| **GET_SOURCES_ATTEMPTS**        | 8.15   | 1.9    | Number of attempts to fetch sources running a job |
| **GITLAB_CI**                   | all    | all    | Mark that job is executed in GitLab CI environment |
| **GITLAB_USER_ID**              | 8.12   | all    | The id of the user who started the job |
| **GITLAB_USER_EMAIL**           | 8.12   | all    | The email of the user who started the job |
| **GITLAB_USER_LOGIN**           | 10.0   | all    | The login username of the user who started the job |
| **GITLAB_USER_NAME**            | 10.0   | all    | The real name of the user who started the job |
| **RESTORE_CACHE_ATTEMPTS**      | 8.15   | 1.9    | Number of attempts to restore the cache running a job |

## 9.0 Renaming

To follow conventions of naming across GitLab, and to further move away from the
`build` term and toward `job` CI variables have been renamed for the 9.0
release.

>**Note:**
Starting with GitLab 9.0, we have deprecated the `$CI_BUILD_*` variables. **You are
strongly advised to use the new variables as we will remove the old ones in
future GitLab releases.**

| 8.x name              | 9.0+ name               |
| --------------------- |------------------------ |
| `CI_BUILD_ID`         | `CI_JOB_ID`             |
| `CI_BUILD_REF`        | `CI_COMMIT_SHA`         |
| `CI_BUILD_TAG`        | `CI_COMMIT_TAG`         |
| `CI_BUILD_REF_NAME`   | `CI_COMMIT_REF_NAME`    |
| `CI_BUILD_REF_SLUG`   | `CI_COMMIT_REF_SLUG`    |
| `CI_BUILD_NAME`       | `CI_JOB_NAME`           |
| `CI_BUILD_STAGE`      | `CI_JOB_STAGE`          |
| `CI_BUILD_REPO`       | `CI_REPOSITORY_URL`     |
| `CI_BUILD_TRIGGERED`  | `CI_PIPELINE_TRIGGERED` |
| `CI_BUILD_MANUAL`     | `CI_JOB_MANUAL`         |
| `CI_BUILD_TOKEN`      | `CI_JOB_TOKEN`          |

## `.gitlab-ci.yml` defined variables

>**Note:**
This feature requires GitLab Runner 0.5.0 or higher and GitLab CI 7.14 or higher.

GitLab CI allows you to add to `.gitlab-ci.yml` variables that are set in the
build environment. The variables are hence saved in the repository, and they
are meant to store non-sensitive project configuration, e.g., `RAILS_ENV` or
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

## Secret variables

NOTE: **Note:**
Group-level secret variables were added in GitLab 9.4.

CAUTION: **Important:**
Be aware that secret variables are not masked, and their values can be shown
in the job logs if explicitly asked to do so. If your project is public or
internal, you can set the pipelines private from your [project's Pipelines
settings](../../user/project/pipelines/settings.md#visibility-of-pipelines).
Follow the discussion in issue [#13784][ce-13784] for masking the secret variables.

GitLab CI allows you to define per-project or per-group secret variables
that are set in the pipeline environment. The secret variables are stored out of
the repository (not in `.gitlab-ci.yml`) and are securely passed to GitLab Runner
making them available during a pipeline run. It's the recommended method to
use for storing things like passwords, SSH keys and credentials.

Project-level secret variables can be added by going to your project's
**Settings > CI/CD**, then finding the section called **Secret variables**.

Likewise, group-level secret variables can be added by going to your group's
**Settings > CI/CD**, then finding the section called **Secret variables**.
Any variables of [subgroups] will be inherited recursively.

![Secret variables](img/secret_variables.png)

Once you set them, they will be available for all subsequent pipelines. You can also
[protect your variables](#protected-secret-variables).

### Protected secret variables

>**Notes:**
This feature requires GitLab 9.3 or higher.

Secret variables could be protected. Whenever a secret variable is
protected, it would only be securely passed to pipelines running on the
[protected branches] or [protected tags]. The other pipelines would not get any
protected variables.

Protected variables can be added by going to your project's
**Settings > CI/CD**, then finding the section called
**Secret variables**, and check "Protected".

Once you set them, they will be available for all subsequent pipelines.

## Deployment variables

>**Note:**
This feature requires GitLab CI 8.15 or higher.

[Project services](../../user/project/integrations/project_services.md) that are
responsible for deployment configuration may define their own variables that
are set in the build environment. These variables are only defined for
[deployment jobs](../environments.md). Please consult the documentation of
the project services that you are using to learn which variables they define.

An example project service that defines deployment variables is
[Kubernetes Service](../../user/project/integrations/kubernetes.md#deployment-variables).

## Debug tracing

> Introduced in GitLab Runner 1.7.

CAUTION: **Warning:**
Enabling debug tracing can have severe security implications. The
output **will** contain the content of all your secret variables and any other
secrets! The output **will** be uploaded to the GitLab server and made visible
in job traces!

By default, GitLab Runner hides most of the details of what it is doing when
processing a job. This behavior keeps job traces short, and prevents secrets
from being leaked into the trace unless your script writes them to the screen.

If a job isn't working as expected, this can make the problem difficult to
investigate; in these cases, you can enable debug tracing in `.gitlab-ci.yml`.
Available on GitLab Runner v1.7+, this feature enables the shell's execution
trace, resulting in a verbose job trace listing all commands that were run,
variables that were set, etc.

Before enabling this, you should ensure jobs are visible to
[team members only](../../user/permissions.md#project-features). You should
also [erase](../pipelines.md#seeing-build-status) all generated job traces
before making them visible again.

To enable debug traces, set the `CI_DEBUG_TRACE` variable to `true`:

```yaml
job_name:
  variables:
    CI_DEBUG_TRACE: "true"
```

Example truncated output with debug trace set to true:

```bash
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
  $'\''git'\'' "fetch" "origin" "--prune" "+refs/heads/*:refs/remotes/origin/*" "+refs/tags/*:refs/tags/*"
else
  $'\''mkdir'\'' "-p" "/builds/gitlab-examples/ci-debug-trace.tmp/git-template"
  $'\''rm'\'' "-r" "-f" "/builds/gitlab-examples/ci-debug-trace"
  $'\''git'\'' "config" "-f" "/builds/gitlab-examples/ci-debug-trace.tmp/git-template/config" "fetch.recurseSubmodules" "false"
  echo $'\''\x1b[32;1mCloning repository...\x1b[0;m'\''
  $'\''git'\'' "clone" "--no-checkout" "https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@example.com/gitlab-examples/ci-debug-trace.git" "/builds/gitlab-examples/ci-debug-trace" "--template" "/builds/gitlab-examples/ci-debug-trace.tmp/git-template"
  $'\''cd'\'' "/builds/gitlab-examples/ci-debug-trace"
fi
echo $'\''\x1b[32;1mChecking out dd648b2e as master...\x1b[0;m'\''
$'\''git'\'' "checkout" "-f" "-q" "dd648b2e48ce6518303b0bb580b2ee32fadaf045"
'
+++ hostname
++ echo 'Running on runner-8a2f473d-project-1796893-concurrent-0 via runner-8a2f473d-machine-1480971377-317a7d0f-digital-ocean-4gb...'
Running on runner-8a2f473d-project-1796893-concurrent-0 via runner-8a2f473d-machine-1480971377-317a7d0f-digital-ocean-4gb...
++ export CI=true
++ CI=true
++ export CI_DEBUG_TRACE=false
++ CI_DEBUG_TRACE=false
++ export CI_COMMIT_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_COMMIT_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_COMMIT_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_COMMIT_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_COMMIT_REF_NAME=master
++ CI_COMMIT_REF_NAME=master
++ export CI_JOB_ID=7046507
++ CI_JOB_ID=7046507
++ export CI_REPOSITORY_URL=https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@example.com/gitlab-examples/ci-debug-trace.git
++ CI_REPOSITORY_URL=https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@example.com/gitlab-examples/ci-debug-trace.git
++ export CI_JOB_TOKEN=xxxxxxxxxxxxxxxxxxxx
++ CI_JOB_TOKEN=xxxxxxxxxxxxxxxxxxxx
++ export CI_PROJECT_ID=1796893
++ CI_PROJECT_ID=1796893
++ export CI_PROJECT_DIR=/builds/gitlab-examples/ci-debug-trace
++ CI_PROJECT_DIR=/builds/gitlab-examples/ci-debug-trace
++ export CI_SERVER=yes
++ CI_SERVER=yes
++ export 'CI_SERVER_NAME=GitLab CI'
++ CI_SERVER_NAME='GitLab CI'
++ export CI_SERVER_VERSION=
++ CI_SERVER_VERSION=
++ export CI_SERVER_REVISION=
++ CI_SERVER_REVISION=
++ export GITLAB_CI=true
++ GITLAB_CI=true
++ export CI=true
++ CI=true
++ export GITLAB_CI=true
++ GITLAB_CI=true
++ export CI_JOB_ID=7046507
++ CI_JOB_ID=7046507
++ export CI_JOB_TOKEN=xxxxxxxxxxxxxxxxxxxx
++ CI_JOB_TOKEN=xxxxxxxxxxxxxxxxxxxx
++ export CI_COMMIT_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_COMMIT_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_COMMIT_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_COMMIT_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_COMMIT_REF_NAME=master
++ CI_COMMIT_REF_NAME=master
++ export CI_COMMIT_NAME=debug_trace
++ CI_JOB_NAME=debug_trace
++ export CI_JOB_STAGE=test
++ CI_JOB_STAGE=test
++ export CI_SERVER_NAME=GitLab
++ CI_SERVER_NAME=GitLab
++ export CI_SERVER_VERSION=8.14.3-ee
++ CI_SERVER_VERSION=8.14.3-ee
++ export CI_SERVER_REVISION=82823
++ CI_SERVER_REVISION=82823
++ export CI_PROJECT_ID=17893
++ CI_PROJECT_ID=17893
++ export CI_PROJECT_NAME=ci-debug-trace
++ CI_PROJECT_NAME=ci-debug-trace
++ export CI_PROJECT_PATH=gitlab-examples/ci-debug-trace
++ CI_PROJECT_PATH=gitlab-examples/ci-debug-trace
++ export CI_PROJECT_NAMESPACE=gitlab-examples
++ CI_PROJECT_NAMESPACE=gitlab-examples
++ export CI_PROJECT_URL=https://example.com/gitlab-examples/ci-debug-trace
++ CI_PROJECT_URL=https://example.com/gitlab-examples/ci-debug-trace
++ export CI_PIPELINE_ID=52666
++ CI_PIPELINE_ID=52666
++ export CI_RUNNER_ID=1337
++ CI_RUNNER_ID=1337
++ export CI_RUNNER_DESCRIPTION=shared-runners-manager-1.example.com
++ CI_RUNNER_DESCRIPTION=shared-runners-manager-1.example.com
++ export 'CI_RUNNER_TAGS=shared, docker, linux, ruby, mysql, postgres, mongo'
++ CI_RUNNER_TAGS='shared, docker, linux, ruby, mysql, postgres, mongo'
++ export CI_REGISTRY=registry.example.com
++ CI_REGISTRY=registry.example.com
++ export CI_DEBUG_TRACE=true
++ CI_DEBUG_TRACE=true
++ export GITLAB_USER_ID=42
++ GITLAB_USER_ID=42
++ export GITLAB_USER_EMAIL=user@example.com
++ GITLAB_USER_EMAIL=user@example.com
++ export VERY_SECURE_VARIABLE=imaverysecurevariable
++ VERY_SECURE_VARIABLE=imaverysecurevariable
++ mkdir -p /builds/gitlab-examples/ci-debug-trace.tmp
++ echo -n '-----BEGIN CERTIFICATE-----
MIIFQzCCBCugAwIBAgIRAL/ElDjuf15xwja1ZnCocWAwDQYJKoZIhvcNAQELBQAw'

...
```

## Using the CI variables in your job scripts

All variables are set as environment variables in the build environment, and
they are accessible with normal methods that are used to access such variables.
In most cases `bash` or `sh` is used to execute the job script.

To access environment variables, use the syntax for your Runner's [shell][shellexecutors].

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
but be aware that this will also expose the values of all the secret variables
you set, in the job log:

```yaml
job_name:
  script:
    - export
```

Example values:

```bash
export CI_JOB_ID="50"
export CI_COMMIT_SHA="1ecfd275763eff1d6b4844ea3168962458c9f27a"
export CI_COMMIT_REF_NAME="master"
export CI_REPOSITORY_URL="https://gitlab-ci-token:abcde-1234ABCD5678ef@example.com/gitlab-org/gitlab-ce.git"
export CI_COMMIT_TAG="1.0.0"
export CI_JOB_NAME="spec:other"
export CI_JOB_STAGE="test"
export CI_JOB_MANUAL="true"
export CI_JOB_TRIGGERED="true"
export CI_JOB_TOKEN="abcde-1234ABCD5678ef"
export CI_PIPELINE_ID="1000"
export CI_PROJECT_ID="34"
export CI_PROJECT_DIR="/builds/gitlab-org/gitlab-ce"
export CI_PROJECT_NAME="gitlab-ce"
export CI_PROJECT_NAMESPACE="gitlab-org"
export CI_PROJECT_PATH="gitlab-org/gitlab-ce"
export CI_PROJECT_URL="https://example.com/gitlab-org/gitlab-ce"
export CI_REGISTRY="registry.example.com"
export CI_REGISTRY_IMAGE="registry.example.com/gitlab-org/gitlab-ce"
export CI_RUNNER_ID="10"
export CI_RUNNER_DESCRIPTION="my runner"
export CI_RUNNER_TAGS="docker, linux"
export CI_SERVER="yes"
export CI_SERVER_NAME="GitLab"
export CI_SERVER_REVISION="70606bf"
export CI_SERVER_VERSION="8.9.0"
export GITLAB_USER_ID="42"
export GITLAB_USER_EMAIL="user@example.com"
export CI_REGISTRY_USER="gitlab-ci-token"
export CI_REGISTRY_PASSWORD="longalfanumstring"
```

## Variables expressions

> Variables expressions were added in GitLab 10.7.

It is possible to use variables expressions with only / except policies in
`.gitlab-ci.yml`. By using this approach you can limit what builds are going to
be created within a pipeline after pushing code to GitLab.

This is particularly useful in combination with secret variables and triggered
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

Each provided variables expression is going to be evaluated before creating
a pipeline.

If any of the conditions in `variables` evaluates to truth when using `only`,
new build is going to be created. If any of the expressions evaluates to truth
when `except` is being used, a build is not going to be created.

This follows usual rules for [`only` / `except` policies][build policies].

### Supported syntax

Below you can find currently supported syntax reference:

1. Equality matching using a string.

    Example: `$VARIABLE == "some value"`

    You can use equality operator `==` to compare a variable content to a
    string. We support both, double quotes and single quotes to define a string
    value, so both `$VARIABLE == "some value"` and `$VARIABLE == 'some value'`
    are supported. `"some value" == $VARIABLE` is correct too.

1. Checking for an undefined value.

    It sometimes happens that you want to check whether variable is defined or
    not. To do that, you can compare variable to `null` value, like
    `$VARIABLE == null`. This expression is going to evaluate to truth if
    variable is not set.

1. Comparing two variables.

    It is possible to compare two variables. `$VARIABLE_1 == $VARIABLE_2`.

1. Variable presence check.

    If you only want to create a job when there is some variable present,
    which means that it is defined and non-empty, you can simply use
    variable name as an expression, like `$STAGING`. If `$STAGING` variable
    is defined, and is non empty, expression will evaluate to truth.

[ce-13784]: https://gitlab.com/gitlab-org/gitlab-ce/issues/13784 "Simple protection of CI secret variables"
[eep]: https://about.gitlab.com/products/ "Available only in GitLab Premium"
[envs]: ../environments.md
[protected branches]: ../../user/project/protected_branches.md
[protected tags]: ../../user/project/protected_tags.md
[runner]: https://docs.gitlab.com/runner/
[shellexecutors]: https://docs.gitlab.com/runner/executors/
[triggered]: ../triggers/README.md
[triggers]: ../triggers/README.md#pass-job-variables-to-a-trigger
[subgroups]: ../../user/group/subgroups/index.md
[build policies]: ../yaml/#only-and-except-complex
