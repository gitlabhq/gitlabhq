## Variables
When receiving a build from GitLab CI, the runner prepares the build environment.
It starts by setting a list of **predefined variables** (Environment Variables) and a list of **user-defined variables**

The variables can be overwritten. They take precedence over each other in this order:
1. Secure variables
1. YAML-defined variables
1. Predefined variables

For example, if you define:
1. API_TOKEN=SECURE as Secure Variable
1. API_TOKEN=YAML as YAML-defined variable

The API_TOKEN will take the Secure Variable value: `SECURE`.

### Predefined variables (Environment Variables)

| Variable                | Runner | Description |
|-------------------------|-------------|
| **CI**                  | 0.4 | Mark that build is executed in CI environment |
| **GITLAB_CI**           | all | Mark that build is executed in GitLab CI environment |
| **CI_SERVER**           | all | Mark that build is executed in CI environment |
| **CI_SERVER_NAME**      | all | CI server that is used to coordinate builds |
| **CI_SERVER_VERSION**   | all | Not yet defined |
| **CI_SERVER_REVISION**  | all | Not yet defined |
| **CI_BUILD_REF**        | all | The commit revision for which project is built |
| **CI_BUILD_TAG**        | 0.5 | The commit tag name. Present only when building tags. |
| **CI_BUILD_NAME**       | 0.5 | The name of the build as defined in `.gitlab-ci.yml` |
| **CI_BUILD_STAGE**      | 0.5 | The name of the stage as defined in `.gitlab-ci.yml` |
| **CI_BUILD_BEFORE_SHA** | all | The first commit that were included in push request |
| **CI_BUILD_REF_NAME**   | all | The branch or tag name for which project is built |
| **CI_BUILD_ID**         | all | The unique id of the current build that GitLab CI uses internally |
| **CI_BUILD_REPO**       | all | The URL to clone the Git repository |
| **CI_BUILD_TRIGGERED**  | 0.5 | The flag to indicate that build was triggered |
| **CI_PROJECT_ID**       | all | The unique id of the current project that GitLab CI uses internally |
| **CI_PROJECT_DIR**      | all | The full path where the repository is cloned and where the build is ran |

**Some of the variables are only available when using runner with at least defined version.**

Example values:

```bash
export CI_BUILD_BEFORE_SHA="9df57456fa9de2a6d335ca5edf9750ed812b9df0"
export CI_BUILD_ID="50"
export CI_BUILD_REF="1ecfd275763eff1d6b4844ea3168962458c9f27a"
export CI_BUILD_REF_NAME="master"
export CI_BUILD_REPO="https://gitlab.com/gitlab-org/gitlab-ce.git"
export CI_BUILD_TAG="1.0.0"
export CI_BUILD_NAME="spec:other"
export CI_BUILD_STAGE="test"
export CI_BUILD_TRIGGERED="true"
export CI_PROJECT_DIR="/builds/gitlab-org/gitlab-ce"
export CI_PROJECT_ID="34"
export CI_SERVER="yes"
export CI_SERVER_NAME="GitLab CI"
export CI_SERVER_REVISION=""
export CI_SERVER_VERSION=""
```

### YAML-defined variables
**This feature requires GitLab Runner 0.5.0 or higher**

GitLab CI allows you to add to `.gitlab-ci.yml` variables that are set in build environment.
The variables are stored in repository and are meant to store non-sensitive project configuration, ie. RAILS_ENV or DATABASE_URL.

```yaml
variables:
  DATABASE_URL: "postgres://postgres@postgres/my_database"
```

These variables can be later used in all executed commands and scripts.

The YAML-defined variables are also set to all created service containers, thus allowing to fine tune them.

More information about Docker integration can be found in [Using Docker Images](../docker/using_docker_images.md).

### User-defined variables (Secure Variables)
**This feature requires GitLab Runner 0.4.0 or higher**

GitLab CI allows you to define per-project **Secure Variables** that are set in build environment. 
The secure variables are stored out of the repository (the `.gitlab-ci.yml`).
These variables are securely stored in GitLab CI database and are hidden in the build log.
It's desired method to use them for storing passwords, secret keys or whatever you want.

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
