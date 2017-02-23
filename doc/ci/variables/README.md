# Variables

When receiving a job from GitLab CI, the [Runner] prepares the build environment.
It starts by setting a list of **predefined variables** (environment variables)
and a list of **user-defined variables**.

## Priority of variables

The variables can be overwritten and they take precedence over each other in
this order:

1. [Trigger variables][triggers] (take precedence over all)
1. [Secret variables](#secret-variables)
1. YAML-defined [job-level variables](../yaml/README.md#job-variables)
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

| Variable                | GitLab | Runner | Description |
|-------------------------|--------|--------|-------------|
| **CI**                  | all    | 0.4    | Mark that job is executed in CI environment |
| **GITLAB_CI**           | all    | all    | Mark that job is executed in GitLab CI environment |
| **CI_SERVER**           | all    | all    | Mark that job is executed in CI environment |
| **CI_SERVER_NAME**      | all    | all    | The name of CI server that is used to coordinate jobs |
| **CI_SERVER_VERSION**   | all    | all    | GitLab version that is used to schedule jobs |
| **CI_SERVER_REVISION**  | all    | all    | GitLab revision that is used to schedule jobs |
| **CI_BUILD_ID**         | all    | all    | The unique id of the current job that GitLab CI uses internally |
| **CI_BUILD_REF**        | all    | all    | The commit revision for which project is built |
| **CI_BUILD_TAG**        | all    | 0.5    | The commit tag name. Present only when building tags. |
| **CI_BUILD_NAME**       | all    | 0.5    | The name of the job as defined in `.gitlab-ci.yml` |
| **CI_BUILD_STAGE**      | all    | 0.5    | The name of the stage as defined in `.gitlab-ci.yml` |
| **CI_BUILD_REF_NAME**   | all    | all    | The branch or tag name for which project is built |
| **CI_BUILD_REF_SLUG**   | 8.15   | all    | `$CI_BUILD_REF_NAME` lowercased, shortened to 63 bytes, and with everything except `0-9` and `a-z` replaced with `-`. Use in URLs and domain names. |
| **CI_BUILD_REPO**       | all    | all    | The URL to clone the Git repository |
| **CI_BUILD_TRIGGERED**  | all    | 0.5    | The flag to indicate that job was [triggered] |
| **CI_BUILD_MANUAL**     | 8.12   | all    | The flag to indicate that job was manually started |
| **CI_BUILD_TOKEN**      | all    | 1.2    | Token used for authenticating with the GitLab Container Registry |
| **CI_PIPELINE_ID**      | 8.10   | 0.5    | The unique id of the current pipeline that GitLab CI uses internally |
| **CI_PROJECT_ID**       | all    | all    | The unique id of the current project that GitLab CI uses internally |
| **CI_PROJECT_NAME**     | 8.10   | 0.5    | The project name that is currently being built |
| **CI_PROJECT_NAMESPACE**| 8.10   | 0.5    | The project namespace (username or groupname) that is currently being built |
| **CI_PROJECT_PATH**     | 8.10   | 0.5    | The namespace with project name |
| **CI_PROJECT_URL**      | 8.10   | 0.5    | The HTTP address to access project |
| **CI_PROJECT_DIR**      | all    | all    | The full path where the repository is cloned and where the job is run |
| **CI_ENVIRONMENT_NAME** | 8.15   | all    | The name of the environment for this job |
| **CI_ENVIRONMENT_SLUG** | 8.15   | all    | A simplified version of the environment name, suitable for inclusion in DNS, URLs, Kubernetes labels, etc. |
| **CI_REGISTRY**         | 8.10   | 0.5    | If the Container Registry is enabled it returns the address of GitLab's Container Registry |
| **CI_REGISTRY_IMAGE**   | 8.10   | 0.5    | If the Container Registry is enabled for the project it returns the address of the registry tied to the specific project |
| **CI_RUNNER_ID**        | 8.10   | 0.5    | The unique id of runner being used |
| **CI_RUNNER_DESCRIPTION** | 8.10 | 0.5    | The description of the runner as saved in GitLab |
| **CI_RUNNER_TAGS**      | 8.10   | 0.5    | The defined runner tags |
| **CI_DEBUG_TRACE**      | all    | 1.7    | Whether [debug tracing](#debug-tracing) is enabled |
| **GET_SOURCES_ATTEMPTS** | 8.15    | 1.9    | Number of attempts to fetch sources running a job |
| **ARTIFACT_DOWNLOAD_ATTEMPTS** | 8.15    | 1.9    | Number of attempts to download artifacts running a job |
| **RESTORE_CACHE_ATTEMPTS** | 8.15    | 1.9    | Number of attempts to restore the cache running a job |
| **GITLAB_USER_ID**      | 8.12   | all    | The id of the user who started the job |
| **GITLAB_USER_EMAIL**   | 8.12   | all    | The email of the user who started the job |


Example values:

```bash
export CI_BUILD_ID="50"
export CI_BUILD_REF="1ecfd275763eff1d6b4844ea3168962458c9f27a"
export CI_BUILD_REF_NAME="master"
export CI_BUILD_REPO="https://gitab-ci-token:abcde-1234ABCD5678ef@example.com/gitlab-org/gitlab-ce.git"
export CI_BUILD_TAG="1.0.0"
export CI_BUILD_NAME="spec:other"
export CI_BUILD_STAGE="test"
export CI_BUILD_MANUAL="true"
export CI_BUILD_TRIGGERED="true"
export CI_BUILD_TOKEN="abcde-1234ABCD5678ef"
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
```

## `.gitlab-ci.yaml` defined variables

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
global defined variables in your job, define an empty array:

```yaml
job_name:
  variables: []
```

## Secret variables

>**Notes:**
- This feature requires GitLab Runner 0.4.0 or higher.
- Be aware that secret variables are not masked, and their values can be shown
  in the job logs if explicitly asked to do so. If your project is public or
  internal, you can set the pipelines private from your project's Pipelines
  settings. Follow the discussion in issue [#13784][ce-13784] for masking the
  secret variables.

GitLab CI allows you to define per-project **secret variables** that are set in
the build environment. The secret variables are stored out of the repository
(`.gitlab-ci.yml`) and are securely passed to GitLab Runner making them
available in the build environment. It's the recommended method to use for
storing things like passwords, secret keys and credentials.

Secret variables can be added by going to your project's
**Settings ➔ CI/CD Pipelines**, then finding the section called
**Secret Variables**.

Once you set them, they will be available for all subsequent jobs.

## Deployment variables

>**Note:**
This feature requires GitLab CI 8.15 or higher.

[Project services](../../user/project/integrations/project_services.md) that are
responsible for deployment configuration may define their own variables that
are set in the build environment. These variables are only defined for
[deployment jobs](../environments.md). Please consult the documentation of
the project services that you are using to learn which variables they define.

An example project service that defines deployment variables is
[Kubernetes Service](../../user/project/integrations/kubernetes.md).

## Debug tracing

> Introduced in GitLab Runner 1.7.
>
> **WARNING:** Enabling debug tracing can have severe security implications. The
  output **will** contain the content of all your secret variables and any other
  secrets! The output **will** be uploaded to the GitLab server and made visible
  in job traces!

By default, GitLab Runner hides most of the details of what it is doing when
processing a job. This behaviour keeps job traces short, and prevents secrets
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
++ export CI_BUILD_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_BUILD_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_BUILD_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_BUILD_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_BUILD_REF_NAME=master
++ CI_BUILD_REF_NAME=master
++ export CI_BUILD_ID=7046507
++ CI_BUILD_ID=7046507
++ export CI_BUILD_REPO=https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@example.com/gitlab-examples/ci-debug-trace.git
++ CI_BUILD_REPO=https://gitlab-ci-token:xxxxxxxxxxxxxxxxxxxx@example.com/gitlab-examples/ci-debug-trace.git
++ export CI_BUILD_TOKEN=xxxxxxxxxxxxxxxxxxxx
++ CI_BUILD_TOKEN=xxxxxxxxxxxxxxxxxxxx
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
++ export CI_BUILD_ID=7046507
++ CI_BUILD_ID=7046507
++ export CI_BUILD_TOKEN=xxxxxxxxxxxxxxxxxxxx
++ CI_BUILD_TOKEN=xxxxxxxxxxxxxxxxxxxx
++ export CI_BUILD_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_BUILD_REF=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_BUILD_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ CI_BUILD_BEFORE_SHA=dd648b2e48ce6518303b0bb580b2ee32fadaf045
++ export CI_BUILD_REF_NAME=master
++ CI_BUILD_REF_NAME=master
++ export CI_BUILD_NAME=debug_trace
++ CI_BUILD_NAME=debug_trace
++ export CI_BUILD_STAGE=test
++ CI_BUILD_STAGE=test
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
++ export 'CI_RUNNER_TAGS=shared, docker, linux, ruby, mysql, postgres, mongo, git-annex'
++ CI_RUNNER_TAGS='shared, docker, linux, ruby, mysql, postgres, mongo, git-annex'
++ export CI_REGISTRY=registry.example.com
++ CI_REGISTRY=registry.example.com
++ export CI_DEBUG_TRACE=true
++ CI_DEBUG_TRACE=true
++ export GITLAB_USER_ID=42
++ GITLAB_USER_ID=42
++ export GITLAB_USER_EMAIL=user@example.com
++ GITLAB_USER_EMAIL=axilleas@axilleas.me
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

To access the variables (predefined and user-defined) in a `bash`/`sh` environment,
prefix the variable name with the dollar sign (`$`):

```
job_name:
  script:
    - echo $CI_job_ID
```

You can also list all environment variables with the `export` command,
but be aware that this will also expose the values of all the secret variables
you set, in the job log:

```
job_name:
  script:
    - export
```

[ce-13784]: https://gitlab.com/gitlab-org/gitlab-ce/issues/13784
[runner]: https://docs.gitlab.com/runner/
[triggered]: ../triggers/README.md
[triggers]: ../triggers/README.md#pass-job-variables-to-a-trigger
