---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating from Jenkins
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If you're migrating from Jenkins to GitLab CI/CD, you are able to create CI/CD
pipelines that replicate and enhance your Jenkins workflows.

## Key similarities and differences

GitLab CI/CD and Jenkins are CI/CD tools with some similarities. Both GitLab
and Jenkins:

- Use stages for collections of jobs.
- Support container-based builds.

Additionally, there are some important differences between the two:

- GitLab CI/CD pipelines are all configured in a YAML format configuration file.
  Jenkins uses either a Groovy format configuration file (declarative pipelines)
  or Jenkins DSL (scripted pipelines).
- GitLab offers [GitLab.com](../../subscriptions/gitlab_com/_index.md), a multi-tenant SaaS service,
  and [GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md), a fully isolated
  single-tenant SaaS service. You can also run your own [GitLab Self-Managed](../../subscriptions/self_managed/_index.md)
  instance. Jenkins deployments must be self-hosted.
- GitLab provides source code management (SCM) out of the box. Jenkins requires a separate
  SCM solution to store code.
- GitLab provides a built-in container registry. Jenkins requires a separate solution
  for storing container images.
- GitLab provides built-in templates for scanning code. Jenkins requires 3rd party plugins
  for scanning code.

## Comparison of features and concepts

Many Jenkins features and concepts have equivalents in GitLab that offer the same
functionality.

### Configuration file

Jenkins can be configured with a [`Jenkinsfile` in the Groovy format](https://www.jenkins.io/doc/book/pipeline/jenkinsfile/). GitLab CI/CD uses a `.gitlab-ci.yml` file by default.

Example of a `Jenkinsfile`:

```groovy
pipeline {
    agent any

    stages {
        stage('hello') {
            steps {
                echo "Hello World"
            }
        }
    }
}
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
stages:
  - hello

hello-job:
  stage: hello
  script:
    - echo "Hello World"
```

### Jenkins pipeline syntax

A Jenkins configuration is composed of a `pipeline` block with sections and directives.
GitLab CI/CD has similar functionality, configured with YAML keywords.

#### Sections

| Jenkins  | GitLab         | Explanation |
|----------|----------------|-------------|
| `agent`  | `image`        | Jenkins pipelines execute on agents, and the `agent` section defines how the pipeline executes, and the Docker container to use. GitLab jobs execute on _runners_, and the `image` keyword defines the container to use. You can configure your own runners in Kubernetes or on any host. |
| `post`   | `after_script` or `stage` | The Jenkins `post` section defines actions that should be performed at the end of a stage or pipeline. In GitLab, use `after_script` for commands to run at the end of a job, and `before_script` for actions to run before the other commands in a job. Use `stage` to select the exact stage a job should run in. GitLab supports both `.pre` and `.post` stages that always run before or after all other defined stages. |
| `stages` | `stages`       | Jenkins stages are groups of jobs. GitLab CI/CD also uses stages, but it is more flexible. You can have multiple stages each with multiple independent jobs. Use `stages` at the top level to the stages and their execution order, and use `stage` at the job level to define the stage for that job. |
| `steps`  | `script`       | Jenkins `steps` define what to execute. GitLab CI/CD uses a `script` section which is similar. The `script` section is a YAML array with separate entries for each command to run in sequence. |

#### Directives

| Jenkins       | GitLab         | Explanation |
|---------------|----------------|-------------|
| `environment` | `variables`    | Jenkins uses `environment` for environment variables. GitLab CI/CD uses the `variables` keyword to define CI/CD variables that can be used during job execution, but also for more dynamic pipeline configuration. These can also be set in the GitLab UI, under CI/CD settings. |
| `options`     | Not applicable | Jenkins uses `options` for additional configuration, including timeouts and retry values. GitLab does not need a separate section for options, all configuration is added as CI/CD keywords at the job or pipeline level, for example `timeout` or `retry`. |
| `parameters`  | Not applicable | In Jenkins, parameters can be required when triggering a pipeline. Parameters are handled in GitLab with CI/CD variables, which can be defined in many places, including the pipeline configuration, project settings, at runtime manually through the UI, or API. |
| `triggers`    | `rules`        | In Jenkins, `triggers` defines when a pipeline should run again, for example through cron notation. GitLab CI/CD can run pipelines automatically for many reasons, including Git changes and merge request updates. Use the `rules` keyword to control which events to run jobs for. Scheduled pipelines are defined in the project settings. |
| `tools`       | Not applicable | In Jenkins, `tools` defines additional tools to install in the environment. GitLab does not have a similar keyword, as the recommendation is to use container images prebuilt with the exact tools required for your jobs. These images can be cached and can be built to already contain the tools you need for your pipelines. If a job needs additional tools, they can be installed as part of a `before_script` section. |
| `input`       | Not applicable | In Jenkins, `input` adds a prompt for user input. Similar to `parameters`, inputs are handled in GitLab through CI/CD variables. |
| `when`        | `rules`        | In Jenkins, `when` defines when a stage should be executed. GitLab also has a `when` keyword, which defines whether a job should start running based on the status of earlier jobs, for example if jobs passed or failed. To control when to add jobs to specific pipelines, use `rules`. |

### Common configurations

This section goes over commonly used CI/CD configurations, showing how they can be converted
from Jenkins to GitLab CI/CD.

[Jenkins pipelines](https://www.jenkins.io/doc/book/pipeline/) generate automated CI/CD jobs
that are triggered when certain event take place, such as a new commit being pushed.
A Jenkins pipeline is defined in a `Jenkinsfile`. The GitLab equivalent is the [`.gitlab-ci.yml` configuration file](../yaml/_index.md).

Jenkins does not provide a place to store source code, so the `Jenkinsfile` must be stored
in a separate source control repository.

#### Jobs

Jobs are a set of commands that run in a set sequence to achieve a particular result.

For example, build a container then deploy it to production, in a `Jenkinsfile`:

```groovy
pipeline {
    agent any
    stages {
        stage('build') {
            agent { docker 'golang:alpine' }
            steps {
                apk update
                go build -o bin/hello
            }
            post {
              always {
                archiveArtifacts artifacts: 'bin/hello'
                onlyIfSuccessful: true
              }
            }
        }
        stage('deploy') {
            agent { docker 'golang:alpine' }
            when {
              branch 'staging'
            }
            steps {
                echo "Deploying to staging"
                scp bin/hello remoteuser@remotehost:/remote/directory
            }
        }
    }
}
```

This example:

- Uses the `golang:alpine` container image.
- Runs a job for building code.
  - Stores the built executable as an artifact.
- Adds a second job to deploy to `staging`, which:
  - Only exists if the commit targets the `staging` branch.
  - Starts after the build stage succeeds.
  - Uses the built executable artifact from the earlier job.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
default:
  image: golang:alpine

stages:
  - build
  - deploy

build-job:
  stage: build
  script:
    - apk update
    - go build -o bin/hello
  artifacts:
    paths:
      - bin/hello
    expire_in: 1 week

deploy-job:
  stage: deploy
  script:
    - echo "Deploying to Staging"
    - scp bin/hello remoteuser@remotehost:/remote/directory
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
  artifacts:
    paths:
      - bin/hello
```

##### Parallel

In Jenkins, jobs that are not dependent on previous jobs can run in parallel when
added to a `parallel` section.

For example, in a `Jenkinsfile`:

```groovy
pipeline {
    agent any
    stages {
        stage('Parallel') {
            parallel {
                stage('Python') {
                    agent { docker 'python:latest' }
                    steps {
                        sh "python --version"
                    }
                }
                stage('Java') {
                    agent { docker 'openjdk:latest' }
                    when {
                        branch 'staging'
                    }
                    steps {
                        sh "java -version"
                    }
                }
            }
        }
    }
}
```

This example runs a Python and a Java job in parallel, using different container images.
The Java job only runs when the `staging` branch is changed.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
python-version:
  image: python:latest
  script:
    - python --version

java-version:
  image: openjdk:latest
  rules:
    - if: $CI_COMMIT_BRANCH == 'staging'
  script:
    - java -version
```

In this case, no extra configuration is needed to make the jobs run in parallel.
Jobs run in parallel by default, each on a different runner assuming there are enough runners
for all the jobs. The Java job is set to only run when the `staging` branch is changed.

##### Matrix

In GitLab you can use a matrix to run a job multiple times in parallel in a single pipeline,
but with different variable values for each instance of the job. Jenkins runs the matrix sequentially.

For example, in a `Jenkinsfile`:

```groovy
matrix {
    axes {
        axis {
            name 'PLATFORM'
            values 'linux', 'mac', 'windows'
        }
        axis {
            name 'ARCH'
            values 'x64', 'x86'
        }
    }
    stages {
        stage('build') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('test') {
            echo "Building $PLATFORM for $ARCH"
        }
        stage('deploy') {
            echo "Building $PLATFORM for $ARCH"
        }
    }
}
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
stages:
  - build
  - test
  - deploy

.parallel-hidden-job:
  parallel:
    matrix:
      - PLATFORM: [linux, mac, windows]
        ARCH: [x64, x86]

build-job:
  extends: .parallel-hidden-job
  stage: build
  script:
    - echo "Building $PLATFORM for $ARCH"

test-job:
  extends: .parallel-hidden-job
  stage: test
  script:
    - echo "Testing $PLATFORM for $ARCH"

deploy-job:
  extends: .parallel-hidden-job
  stage: deploy
  script:
    - echo "Testing $PLATFORM for $ARCH"
```

#### Container Images

In GitLab you can [run your CI/CD jobs in separate, isolated Docker containers](../docker/using_docker_images.md)
using the [image](../yaml/_index.md#image) keyword.

For example, in a `Jenkinsfile`:

```groovy
stage('Version') {
    agent { docker 'python:latest' }
    steps {
        echo 'Hello Python'
        sh 'python --version'
    }
}
```

This example shows commands running in a `python:latest` container.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
version-job:
  image: python:latest
  script:
    - echo "Hello Python"
    - python --version
```

#### Variables

In GitLab, use the `variables` keyword to define [CI/CD variables](../variables/_index.md).
Use variables to reuse configuration data, have more dynamic configuration, or store important values.
Variables can be defined either globally or per job.

For example, in a `Jenkinsfile`:

```groovy
pipeline {
    agent any
    environment {
        NAME = 'Fern'
    }
    stages {
        stage('English') {
            environment {
                GREETING = 'Hello'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
        stage('Spanish') {
            environment {
                GREETING = 'Hola'
            }
            steps {
                sh 'echo "$GREETING $NAME"'
            }
        }
    }
}
```

This example shows how variables can be used to pass values to commands in jobs.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
default:
  image: alpine:latest

stages:
  - greet

variables:
  NAME: "Fern"

english:
  stage: greet
  variables:
    GREETING: "Hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  stage: greet
  variables:
    GREETING: "Hola"
  script:
    - echo "$GREETING $NAME"
```

Variables can also be [set in the GitLab UI, in the CI/CD settings](../variables/_index.md#define-a-cicd-variable-in-the-ui).
In some cases, you can use [protected](../variables/_index.md#protect-a-cicd-variable)
and [masked](../variables/_index.md#mask-a-cicd-variable) variables for secret values.
These variables can be accessed in pipeline jobs the same as variables defined in the
configuration file.

For example, in a `Jenkinsfile`:

```groovy
pipeline {
    agent any
    stages {
        stage('Example Username/Password') {
            environment {
                AWS_ACCESS_KEY = credentials('aws-access-key')
            }
            steps {
                sh 'my-login-script.sh $AWS_ACCESS_KEY'
            }
        }
    }
}
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
login-job:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

Additionally, GitLab CI/CD makes [predefined variables](../variables/predefined_variables.md)
available to every pipeline and job which contain values relevant to the pipeline and repository.

#### Expressions and conditionals

When a new pipeline starts, GitLab checks which jobs should run in that pipeline.
You can configure jobs to run depending on factors like the status of variables,
or the pipeline type.

For example, in a `Jenkinsfile`:

```groovy
stage('deploy_staging') {
    agent { docker 'alpine:latest' }
    when {
        branch 'staging'
    }
    steps {
        echo "Deploying to staging"
    }
}
```

In this example, the job only runs when the branch we are committing to is named `staging`.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
deploy_staging:
  stage: deploy
  script:
    - echo "Deploy to staging server"
  rules:
    - if: '$CI_COMMIT_BRANCH == staging'
```

#### Runners

Like Jenkins agents, GitLab runners are the hosts that run jobs. If you are using GitLab.com,
you can use the [instance runner fleet](../runners/_index.md) to run jobs without provisioning
your own runners.

To convert a Jenkins agent for use with GitLab CI/CD, uninstall the agent and then
[install and register a runner](../runners/_index.md). Runners do not require much overhead,
so you might be able to use similar provisioning as the Jenkins agents you were using.

Some key details about runners:

- Runners can be [configured](../runners/runners_scope.md) to be shared across an instance,
  a group, or dedicated to a single project.
- You can use the [`tags` keyword](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)
  for finer control, and associate runners with specific jobs. For example, you can use a tag for jobs that
  require dedicated, more powerful, or specific hardware.
- GitLab has [autoscaling for runners](https://docs.gitlab.com/runner/configuration/autoscale.html).
  Use autoscaling to provision runners only when needed and scale down when not needed.

For example, in a `Jenkinsfile`:

```groovy
pipeline {
    agent none
    stages {
        stage('Linux') {
            agent {
                label 'linux'
            }
            steps {
                echo "Hello, $USER"
            }
        }
        stage('Windows') {
            agent {
                label 'windows'
            }
            steps {
                echo "Hello, %USERNAME%"
            }
        }
    }
}
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
linux_job:
  stage: build
  tags:
    - linux
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows
  script:
    - echo "Hello, %USERNAME%"
```

#### Artifacts

In GitLab, any job can use the [`artifacts`](../yaml/_index.md#artifacts) keyword to define a set of artifacts to
be stored when a job completes. [Artifacts](../jobs/job_artifacts.md) are files that can be used in later jobs,
for example for testing or deployment.

For example, in a `Jenkinsfile`:

```groovy
stages {
    stage('Generate Cat') {
        steps {
            sh 'touch cat.txt'
            sh 'echo "meow" > cat.txt'
        }
        post {
            always {
                archiveArtifacts artifacts: 'cat.txt'
                onlyIfSuccessful: true
            }
        }
    }
    stage('Use Cat') {
        steps {
            sh 'cat cat.txt'
        }
    }
  }
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
stages:
  - generate
  - use

generate_cat:
  stage: generate
  script:
    - touch cat.txt
    - echo "meow" > cat.txt
  artifacts:
    paths:
      - cat.txt
    expire_in: 1 week

use_cat:
  stage: use
  script:
    - cat cat.txt
  artifacts:
    paths:
      - cat.txt
```

#### Caching

A [cache](../caching/_index.md) is created when a job downloads one or more files and
saves them for faster access in the future. Subsequent jobs that use the same cache don't have to download the files again,
so they execute more quickly. The cache is stored on the runner and uploaded to S3 if
[distributed cache is enabled](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching).
Jenkins core does not provide caching.

For example, in a `.gitlab-ci.yml` file:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

### Jenkins plugins

Some functionality in Jenkins that is enabled through plugins is supported natively
in GitLab with keywords and features that offer similar functionality. For example:

| Jenkins plugin                                                                    | GitLab feature |
|-----------------------------------------------------------------------------------|----------------|
| [Build Timeout](https://plugins.jenkins.io/build-timeout/)                        | [`timeout` keyword](../yaml/_index.md#timeout) |
| [Cobertura](https://plugins.jenkins.io/cobertura/)                                | [Coverage report artifacts](../yaml/artifacts_reports.md#artifactsreportscoverage_report) and [Code coverage](../testing/code_coverage/_index.md) |
| [Code coverage API](https://plugins.jenkins.io/code-coverage-api/)                | [Code coverage](../testing/code_coverage/_index.md) and [Coverage visualization](../testing/code_coverage/_index.md#coverage-visualization) |
| [Embeddable Build Status](https://plugins.jenkins.io/embeddable-build-status/)    | [Pipeline status badges](../../user/project/badges.md#pipeline-status-badges) |
| [JUnit](https://plugins.jenkins.io/junit/)                                        | [JUnit test report artifacts](../yaml/artifacts_reports.md#artifactsreportsjunit) and [Unit test reports](../testing/unit_test_reports.md) |
| [Mailer](https://plugins.jenkins.io/mailer/)                                      | [Notification emails](../../user/profile/notifications.md) |
| [Parameterized Trigger Plugin](https://plugins.jenkins.io/parameterized-trigger/) | [`trigger` keyword](../yaml/_index.md#trigger) and [downstream pipelines](../pipelines/downstream_pipelines.md) |
| [Role-based Authorization Strategy](https://plugins.jenkins.io/role-strategy/)    | GitLab [permissions and roles](../../user/permissions.md) |
| [Timestamper](https://plugins.jenkins.io/timestamper/)                            | [Job](../jobs/_index.md) logs are time stamped by default |

### Security Scanning features

You might have used plugins for things like code quality, security, or static application scanning in Jenkins.
GitLab provides [security scanners](../../user/application_security/_index.md) out-of-the-box to detect
vulnerabilities in all parts of the SDLC. You can add these plugins in GitLab using templates, for example to add
SAST scanning to your pipeline, add the following to your `.gitlab-ci.yml`:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

You can customize the behavior of security scanners by using CI/CD variables, for example
with the [SAST scanners](../../user/application_security/sast/_index.md#available-cicd-variables).

### Secrets Management

Privileged information, often referred to as "secrets", is sensitive information
or credentials you need in your CI/CD workflow. You might use secrets to unlock protected resources
or sensitive information in tools, applications, containers, and cloud-native environments.

Secrets management in Jenkins is usually handled with the `Secret` type field or the
Credentials Plugin. Credentials stored in the Jenkins settings can be exposed to
jobs as environment variables by using the Credentials Binding plugin.

For secrets management in GitLab, you can use one of the supported integrations
for an external service. These services securely store secrets outside of your GitLab project,
though you must have a subscription for the service:

- [HashiCorp Vault](../secrets/hashicorp_vault.md)
- [Azure Key Vault](../secrets/azure_key_vault.md)
- [Google Cloud Secret Manager](../secrets/gcp_secret_manager.md)

GitLab also supports [OIDC authentication](../secrets/id_token_authentication.md)
for other third party services that support OIDC.

Additionally, you can make credentials available to jobs by storing them in CI/CD variables, though secrets
stored in plain text are susceptible to accidental exposure, [the same as in Jenkins](https://www.jenkins.io/doc/developer/security/secrets/#storing-secrets).
You should always store sensitive information in [masked](../variables/_index.md#mask-a-cicd-variable)
and [protected](../variables/_index.md#protect-a-cicd-variable) variables, which mitigates
some of the risk.

Also, never store secrets as variables in your `.gitlab-ci.yml` file, which is public to all
users with access to the project. Storing sensitive information in variables should
only be done in [the project, group, or instance settings](../variables/_index.md#define-a-cicd-variable-in-the-ui).

Review the [security guidelines](../variables/_index.md#cicd-variable-security) to improve
the safety of your CI/CD variables.

## Planning and Performing a Migration

The following list of recommended steps was created after observing organizations
that were able to quickly complete this migration.

### Create a Migration Plan

Before starting a migration you should create a [migration plan](plan_a_migration.md) to make preparations for the migration. For a migration from Jenkins, ask yourself the following questions in preparation:

- What plugins are used by jobs in Jenkins today?
  - Do you know what these plugins do exactly?
  - Do any plugins wrap a common build tool? For example, Maven, Gradle, or NPM?
- What is installed on the Jenkins agents?
- Are there any shared libraries in use?
- How are you authenticating from Jenkins? Are you using SSH keys, API tokens, or other secrets?
- Are there other projects that you need to access from your pipeline?
- Are there credentials in Jenkins to access outside services? For example Ansible Tower,
  Artifactory, or other Cloud Providers or deployment targets?

### Prerequisites

Before doing any migration work, you should first:

1. Get familiar with GitLab.
   - Read about the [key GitLab CI/CD features](../_index.md).
   - Follow tutorials to create [your first GitLab pipeline](../quick_start/_index.md) and [more complex pipelines](../quick_start/tutorial.md) that build, test, and deploys a static site.
   - Review the [CI/CD YAML syntax reference](../yaml/_index.md).
1. Set up and configure GitLab.
1. Test your GitLab instance.
   - Ensure [runners](../runners/_index.md) are available, either by using shared GitLab.com runners or installing new runners.

### Migration Steps

1. Migrate projects from your SCM solution to GitLab.
   - (Recommended) You can use the available [importers](../../user/project/import/_index.md)
     to automate mass imports from external SCM providers.
   - You can [import repositories by URL](../../user/project/import/repo_by_url.md).
1. Create a `.gitlab-ci.yml` file in each project.
1. Migrate Jenkins configuration to GitLab CI/CD jobs and configure them to show results directly in merge requests.
1. Migrate deployment jobs by using [cloud deployment templates](../cloud_deployment/_index.md),
   [environments](../environments/_index.md), and the [GitLab agent for Kubernetes](../../user/clusters/agent/_index.md).
1. Check if any CI/CD configuration can be reused across different projects, then create
   and share CI/CD templates.
1. Check the [pipeline efficiency documentation](../pipelines/pipeline_efficiency.md)
   to learn how to make your GitLab CI/CD pipelines faster and more efficient.

### Additional Resources

- You can use the [JenkinsFile Wrapper](https://gitlab.com/gitlab-org/jfr-container-builder/)
  to run a complete Jenkins instance inside of a GitLab CI/CD job, including plugins. Use this tool to help ease the transition to GitLab CI/CD, by delaying the migration of less urgent pipelines.

  NOTE:
  The JenkinsFile Wrapper is not packaged with GitLab and falls outside of the scope of support.
  For more information, see the [Statement of Support](https://about.gitlab.com/support/statement-of-support/).

If you have questions that are not answered here, the [GitLab community forum](https://forum.gitlab.com/) can be a great resource.
