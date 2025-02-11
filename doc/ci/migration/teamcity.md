---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating from TeamCity
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If you're migrating from TeamCity to GitLab CI/CD, you can create CI/CD
pipelines that replicate and enhance your TeamCity workflows.

## Key similarities and differences

GitLab CI/CD and TeamCity are CI/CD tools with some similarities. Both GitLab and TeamCity:

- Are flexible enough to run jobs for most languages.
- Can be deployed either on-premises or in the cloud.

Additionally, there are some important differences between the two:

- GitLab CI/CD pipelines are configured in a YAML format configuration file, which
  you can edit manually or with the [pipeline editor](../pipeline_editor/_index.md).
  TeamCity pipelines can be configured from the UI or using Kotlin DSL.
- GitLab is a DevSecOps platform with built-in SCM, container registry, security scanning, and more.
  TeamCity requires separate solutions for these capabilities, usually provided by integrations.

### Configuration file

TeamCity can be [configured from the UI](https://www.jetbrains.com/help/teamcity/creating-and-editing-build-configurations.html)
or in the [`Teamcity Configuration` file in the Kotlin DSL format](https://www.jetbrains.com/help/teamcity/kotlin-dsl.html).
A TeamCity build configuration is a set of instructions that defines how a software project should be built,
tested, and deployed. The configuration includes parameters and settings necessary for automating
the CI/CD process in TeamCity.

In GitLab, the equivalent of a TeamCity build configuration is the `.gitlab-ci.yml` file.
This file defines the CI/CD pipeline for a project, specifying the stages, jobs,
and commands needed to build, test, and deploy the project.

## Comparison of features and concepts

Many TeamCity features and concepts have equivalents in GitLab that offer the same
functionality.

### Jobs

TeamCity uses build configurations, which consist of multiple build steps where you define
commands or scripts to execute tasks such as compiling code, running tests, and packaging artifacts.

The following is an example of a TeamCity project configuration in a Kotlin DSL format that builds a Docker file and runs unit tests:

```kotlin
package _Self.buildTypes

import jetbrains.buildServer.configs.kotlin.*
import jetbrains.buildServer.configs.kotlin.buildFeatures.perfmon
import jetbrains.buildServer.configs.kotlin.buildSteps.dockerCommand
import jetbrains.buildServer.configs.kotlin.buildSteps.nodeJS
import jetbrains.buildServer.configs.kotlin.triggers.vcs

object BuildTest : BuildType({
    name = "Build & Test"

    vcs {
        root(HttpsGitlabComRutshahCicdDemoGitRefsHeadsMain)
    }

    steps {
        dockerCommand {
            id = "DockerCommand"
            commandType = build {
                source = file {
                    path = "Dockerfile"
                }
            }
        }
        nodeJS {
            id = "nodejs_runner"
            workingDir = "app"
            shellScript = """
                npm install jest-teamcity --no-save
                npm run test -- --reporters=jest-teamcity
            """.trimIndent()
        }
    }

    triggers {
        vcs {
        }
    }

    features {
        perfmon {
        }
    }
})
```

In GitLab CI/CD, you define jobs with the tasks to execute as part of the pipeline.
Each job can have one or more build steps defined in it.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file for the example above would be:

```yaml
workflow:
  rules:
    - if: $CI_COMMIT_BRANCH != "main" || $CI_PIPELINE_SOURCE != "merge_request_event"
      when: never
    - when: always

stages:
  - build
  - test

build-job:
  image: docker:20.10.16
  stage: build
  services:
    - docker:20.10.16-dind
  script:
    - docker build -t cicd-demo:0.1 .

run_unit_tests:
  image: node:17-alpine3.14
  stage: test
  before_script:
    - cd app
    - npm install
  script:
    - npm test
  artifacts:
    when: always
    reports:
      junit: app/junit.xml
```

### Pipeline triggers

[TeamCity Triggers](https://www.jetbrains.com/help/teamcity/configuring-build-triggers.html) define conditions that initiate a build, including VCS changes,
scheduled triggers, or builds triggered by other builds.

In GitLab CI/CD, pipelines can be triggered automatically for various events, like changes to branches or merge requests and new tags. Pipelines can also be triggered manually, using an [API](../triggers/_index.md), or with [scheduled pipelines](../pipelines/schedules.md). For more information, see [CI/CD pipelines](../pipelines/_index.md).

### Variables

In TeamCity, you [define build parameters and environment variables](https://www.jetbrains.com/help/teamcity/using-build-parameters.html)
in the build configuration settings.

In GitLab, use the `variables` keyword to define [CI/CD variables](../variables/_index.md).
Use variables to reuse configuration data, have more dynamic configuration, or store important values.
Variables can be defined either globally or per job.

For example, a GitLab CI/CD `.gitlab-ci.yml` file that uses variables:

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

### Artifacts

Build configurations in TeamCity allow you to define [artifacts](https://www.jetbrains.com/help/teamcity/build-artifact.html) generated during the build process.

In GitLab, any job can use the [`artifacts`](../yaml/_index.md#artifacts) keyword to define a set of artifacts to
be stored when a job completes. [Artifacts](../jobs/job_artifacts.md) are files that can be used in later jobs,
for testing or deployment.

For example, a GitLab CI/CD `.gitlab-ci.yml` file that uses artifacts:

```yaml
stage:
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
```

### Runners

The equivalent of [TeamCity agents](https://www.jetbrains.com/help/teamcity/build-agent.html) in GitLab are Runners.

In GitLab CI/CD, runners are the services that execute jobs. If you are using GitLab.com, you can use the
[instance runner fleet](../runners/_index.md) to run jobs without provisioning your own self-managed runners.

Some key details about runners:

- Runners can be [configured](../runners/runners_scope.md) to be shared across an instance,
  a group, or dedicated to a single project.
- You can use the [`tags` keyword](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)
  for finer control, and associate runners with specific jobs. For example, you can use a tag for jobs that
  require dedicated, more powerful, or specific hardware.
- GitLab has [autoscaling for runners](https://docs.gitlab.com/runner/runner_autoscale/).
  Use autoscaling to provision runners only when needed and scale down when not needed.

### TeamCity build features & plugins

Some functionality in TeamCity that is enabled through build features & plugins
is supported in GitLab CI/CD natively with CI/CD keywords and features.

| TeamCity plugin                                                                                                                    | GitLab feature |
|------------------------------------------------------------------------------------------------------------------------------------|----------------|
| [Code coverage](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html#Code+Coverage+in+TeamCity) | [Code coverage](../testing/code_coverage/_index.md) and [Test coverage visualization](../testing/code_coverage/_index.md#coverage-visualization) |
| [Unit Test Report](https://www.jetbrains.com/help/teamcity/configuring-test-reports-and-code-coverage.html)                        | [JUnit test report artifacts](../yaml/artifacts_reports.md#artifactsreportsjunit) and [Unit test reports](../testing/unit_test_reports.md) |
| [Notifications](https://www.jetbrains.com/help/teamcity/configuring-notifications.html)                                            | [Notification emails](../../user/profile/notifications.md) and [Slack](../../user/project/integrations/gitlab_slack_application.md) |

## Planning and performing a migration

The following list of recommended steps was created after observing organizations
that were able to quickly complete a migration to GitLab CI/CD.

### Create a migration plan

Before starting a migration you should create a [migration plan](plan_a_migration.md)
to make preparations for the migration.

For a migration from TeamCity, ask yourself the following questions in preparation:

- What plugins are used by jobs in TeamCity today?
  - Do you know what these plugins do exactly?
- What is installed on the TeamCity agents?
- Are there any shared libraries in use?
- How are you authenticating from TeamCity? Are you using SSH keys, API tokens, or other secrets?
- Are there other projects that you need to access from your pipeline?
- Are there credentials in TeamCity to access outside services? For example Ansible Tower,
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

### Migration steps

1. Migrate projects from your SCM solution to GitLab.
   - (Recommended) You can use the available [importers](../../user/project/import/_index.md)
     to automate mass imports from external SCM providers.
   - You can [import repositories by URL](../../user/project/import/repo_by_url.md).
1. Create a `.gitlab-ci.yml` file in each project.
1. Migrate TeamCity configuration to GitLab CI/CD jobs and configure them to show results directly in merge requests.
1. Migrate deployment jobs by using [cloud deployment templates](../cloud_deployment/_index.md),
   [environments](../environments/_index.md), and the [GitLab agent for Kubernetes](../../user/clusters/agent/_index.md).
1. Check if any CI/CD configuration can be reused across different projects, then create
   and share [CI/CD templates](../examples/_index.md#cicd-templates) or [CI/CD components](../components/_index.md).
1. See [pipeline efficiency](../pipelines/pipeline_efficiency.md)
   to learn how to make your GitLab CI/CD pipelines faster and more efficient.

If you have questions that are not answered here, the [GitLab community forum](https://forum.gitlab.com/) can be a great resource.
