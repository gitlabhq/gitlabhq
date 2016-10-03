## Variables

When receiving a build from GitLab CI, the runner prepares the build environment.
It starts by setting a list of **predefined variables** (Environment Variables) and a list of **user-defined variables**

The variables can be overwritten. They take precedence over each other in this order:
1. Trigger variables
1. Secure variables
1. YAML-defined job-level variables
1. YAML-defined global variables
1. Predefined variables

For example, if you define:
1. `API_TOKEN=SECURE` as Secure Variable
1. `API_TOKEN=YAML` as YAML-defined variable

The `API_TOKEN` will take the Secure Variable value: `SECURE`.

### Predefined variables (Environment Variables)

| Variable                | GitLab | Runner | Description |
|-------------------------|--------|--------|-------------|
| **CI**                  | all    | 0.4    | Mark that build is executed in CI environment |
| **GITLAB_CI**           | all    | all    | Mark that build is executed in GitLab CI environment |
| **CI_SERVER**           | all    | all    | Mark that build is executed in CI environment |
| **CI_SERVER_NAME**      | all    | all    | The name of CI server that is used to coordinate builds |
| **CI_SERVER_VERSION**   | all    | all    | GitLab version that is used to schedule builds |
| **CI_SERVER_REVISION**  | all    | all    | GitLab revision that is used to schedule builds |
| **CI_BUILD_ID**         | all    | all    | The unique id of the current build that GitLab CI uses internally |
| **CI_BUILD_REF**        | all    | all    | The commit revision for which project is built |
| **CI_BUILD_TAG**        | all    | 0.5    | The commit tag name. Present only when building tags. |
| **CI_BUILD_NAME**       | all    | 0.5    | The name of the build as defined in `.gitlab-ci.yml` |
| **CI_BUILD_STAGE**      | all    | 0.5    | The name of the stage as defined in `.gitlab-ci.yml` |
| **CI_BUILD_REF_NAME**   | all    | all    | The branch or tag name for which project is built |
| **CI_BUILD_REPO**       | all    | all    | The URL to clone the Git repository |
| **CI_BUILD_TRIGGERED**  | all    | 0.5    | The flag to indicate that build was [triggered] |
| **CI_BUILD_MANUAL**     | 8.12   | all    | The flag to indicate that build was manually started |
| **CI_BUILD_TOKEN**      | all    | 1.2    | Token used for authenticating with the GitLab Container Registry |
| **CI_PIPELINE_ID**      | 8.10   | 0.5    | The unique id of the current pipeline that GitLab CI uses internally |
| **CI_PROJECT_ID**       | all    | all    | The unique id of the current project that GitLab CI uses internally |
| **CI_PROJECT_NAME**     | 8.10   | 0.5    | The project name that is currently being built |
| **CI_PROJECT_NAMESPACE**| 8.10   | 0.5    | The project namespace (username or groupname) that is currently being built |
| **CI_PROJECT_PATH**     | 8.10   | 0.5    | The namespace with project name |
| **CI_PROJECT_URL**      | 8.10   | 0.5    | The HTTP address to access project |
| **CI_PROJECT_DIR**      | all    | all    | The full path where the repository is cloned and where the build is run |
| **CI_REGISTRY**         | 8.10   | 0.5    | If the Container Registry is enabled it returns the address of GitLab's Container Registry |
| **CI_REGISTRY_IMAGE**   | 8.10   | 0.5    | If the Container Registry is enabled for the project it returns the address of the registry tied to the specific project |
| **CI_RUNNER_ID**        | 8.10   | 0.5    | The unique id of runner being used |
| **CI_RUNNER_DESCRIPTION** | 8.10 | 0.5    | The description of the runner as saved in GitLab |
| **CI_RUNNER_TAGS**      | 8.10   | 0.5    | The defined runner tags |
| **GITLAB_USER_ID**      | 8.12   | all    | The id of the user who started the build |
| **GITLAB_USER_EMAIL**   | 8.12   | all    | The email of the user who started the build |

**Some of the variables are only available when using runner with at least defined version.**

Example values:

```bash
export CI_BUILD_ID="50"
export CI_BUILD_REF="1ecfd275763eff1d6b4844ea3168962458c9f27a"
export CI_BUILD_REF_NAME="master"
export CI_BUILD_REPO="https://gitab-ci-token:abcde-1234ABCD5678ef@gitlab.com/gitlab-org/gitlab-ce.git"
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
export CI_PROJECT_URL="https://gitlab.com/gitlab-org/gitlab-ce"
export CI_REGISTRY="registry.gitlab.com"
export CI_REGISTRY_IMAGE="registry.gitlab.com/gitlab-org/gitlab-ce"
export CI_RUNNER_ID="10"
export CI_RUNNER_DESCRIPTION="my runner"
export CI_RUNNER_TAGS="docker, linux"
export CI_SERVER="yes"
export CI_SERVER_NAME="GitLab"
export CI_SERVER_REVISION="70606bf"
export CI_SERVER_VERSION="8.9.0"
export GITLAB_USER_ID="42"
export GITLAB_USER_EMAIL="alexzander@sporer.com"
```

### YAML-defined variables
**This feature requires GitLab Runner 0.5.0 or higher and GitLab CI 7.14 or higher **

GitLab CI allows you to add to `.gitlab-ci.yml` variables that are set in build environment.
The variables are stored in repository and are meant to store non-sensitive project configuration, ie. RAILS_ENV or DATABASE_URL.

```yaml
variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
```

These variables can be later used in all executed commands and scripts.

The YAML-defined variables are also set to all created service containers, thus allowing to fine tune them.

Variables can be defined at a global level, but also at a job level.

More information about Docker integration can be found in [Using Docker Images](../docker/using_docker_images.md).

### User-defined variables (Secure Variables)
**This feature requires GitLab Runner 0.4.0 or higher**

GitLab CI allows you to define per-project **Secure Variables** that are set in
the build environment.
The secure variables are stored out of the repository (the `.gitlab-ci.yml`).
The variables are securely passed to GitLab Runner and are available in the
build environment.
It's desired method to use them for storing passwords, secret keys or whatever
you want.

**The value of the variable can be shown in build log if explicitly asked to do so.**
If your project is public or internal you can make the builds private.

Secure Variables can added by going to `Project > Variables > Add Variable`.

They will be available for all subsequent builds.

### Use variables
The variables are set as environment variables in build environment and are accessible with normal methods that are used to access such variables.
In most cases the **bash** is used to execute build script.
To access variables (predefined and user-defined) in bash environment, prefix the variable name with `$`:
```
job_name:
  script:
    - echo $CI_BUILD_ID
```

You can also list all environment variables with `export` command,
but be aware that this will also expose value of all **Secure Variables** in build log:
```
job_name:
  script:
    - export
```

[triggered]: ../triggers/README.md
