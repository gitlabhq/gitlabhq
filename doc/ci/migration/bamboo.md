---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating from Bamboo
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

This migration guide looks at how you can migrate from Atlassian Bamboo to GitLab CI/CD.
The focus is on [Bamboo Specs YAML](https://docs.atlassian.com/bamboo-specs-docs/8.1.12/specs.html?yaml)
exported from the Bamboo UI or stored in Spec repositories.

## GitLab CI/CD Primer

If you are new to GitLab CI/CD, use the [Getting started guide](../_index.md) to learn
the basic concepts and how to create your first [`.gitlab-ci.yml` file](../quick_start/_index.md).
If you already have some experience using GitLab CI/CD, you can review [CI/CD YAML syntax reference](../yaml/_index.md)
to see the full list of available keywords.

You can also take a look at [Auto DevOps](../../topics/autodevops/_index.md), which automatically
builds, tests, and deploys your application using a collection of
pre-configured features and integrations.

## Key similarities and differences

### Offerings

Atlassian offers Bamboo in its Cloud (SaaS) or Data center (self-hosted) options.
A third Server option is scheduled for [EOL on February 15, 2024](https://about.gitlab.com/blog/2023/09/26/atlassian-server-ending-move-to-a-single-devsecops-platform/).

These options are similar to [GitLab.com](../../subscriptions/gitlab_com/_index.md)
and [GitLab Self-Managed](../../subscriptions/self_managed/_index.md). GitLab also offers
[GitLab Dedicated](../../subscriptions/gitlab_dedicated/_index.md), a fully isolated
single-tenant SaaS service.

### Agents vs Runners

Bamboo uses [agents](https://confluence.atlassian.com/bamboo/configuring-agents-289277172.html)
to run builds and deployments. Agents can be local agents running on the Bamboo server or
remote agents running external to the server.

GitLab uses a similar concept to agents called [runners](https://docs.gitlab.com/runner/)
which use [executors](https://docs.gitlab.com/runner/executors/) to run builds.

Examples of executors are shell, Docker, or Kubernetes. You can choose to use [GitLab.com runners](../runners/_index.md)
or deploy your own [self-managed runners](https://docs.gitlab.com/runner/install/index.html).

### Workflow

[Bamboo workflow](https://confluence.atlassian.com/bamboo/understanding-the-bamboo-ci-server-289277285.html)
is organized into projects. Projects are used to organize Plans, along with variables,
shared credentials, and permissions needed by multiple plans. A plan groups jobs into
stages and links to code repositories where applications to be built are hosted.
Repositories could be in Bitbucket, GitLab, or other services.

A job is a series of tasks that are executed sequentially on the same Bamboo agent.
CI and deployments are treated separately in Bamboo. [Deployment project workflow](https://confluence.atlassian.com/bamboo/deployment-projects-workflow-362971857.html)
is different from the build plans workflow. [Learn more](https://confluence.atlassian.com/bamboo/understanding-the-bamboo-ci-server-289277285.html)
about Bamboo workflow.

GitLab CI/CD uses a similar workflow. Jobs are organized into [stages](../yaml/_index.md#stage),
and projects have individual `.gitlab-ci.yml` configuration files or include existing templates.

### Templating & Configuration as Code

#### Bamboo Specs

Bamboo plans can be configured in either the Web UI or with Bamboo Specs.
[Bamboo Specs](https://confluence.atlassian.com/bamboo/bamboo-specs-894743906.html)
is configuration as code, which can be written in Java or YAML. [YAML Specs](https://docs.atlassian.com/bamboo-specs-docs/8.1.12/specs.html?yaml)
is the easiest to use but lacks in Bamboo feature coverage. [Java Specs](https://docs.atlassian.com/bamboo-specs-docs/8.1.12/specs.html?java)
has complete Bamboo feature coverage and can be written in any JVM language like Groovy, Scala, or Kotlin.
If you configured your plans using the Web UI, you can [export your Bamboo configuration](https://confluence.atlassian.com/bamboo/exporting-existing-plan-configuration-to-bamboo-yaml-specs-1018270696.html)
into Bamboo Specs.

Bamboo Specs can also be [repository-stored](https://confluence.atlassian.com/bamboo/enabling-repository-stored-bamboo-specs-938641941.html).

#### `.gitlab-ci.yml` configuration file

GitLab, by default, uses a `.gitlab-ci.yml` file for CI/CD configuration.
Alternatively, [Auto DevOps](../../topics/autodevops/_index.md) can automatically build,
test, and deploy your application without a manually configured `.gitlab-ci.yml` file.

GitLab CI/CD configuration can be organized into templates that are reusable across projects.
GitLab also provides pre-built [templates](../examples/_index.md#cicd-templates)
that help you get started quickly and avoid re-inventing the wheel.

### Configuration

#### Bamboo YAML Spec syntax

This Bamboo Spec was exported from a Bamboo Server instance, which creates quite verbose output:

```yaml
version: 2
plan:
  project-key: AB
  key: TP
  name: test plan
stages:
  - Default Stage:
      manual: false
      final: false
      jobs:
        - Default Job
Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v  # Print out ruby version for debugging
          bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
          bundle install -j $(nproc)
          rubocop
          rspec spec
      description: run bundler
  artifact-subscriptions: []
repositories:
  - Demo Project:
      scope: global
triggers:
  - polling:
      period: '180'
branches:
  create: manually
  delete: never
  link-to-jira: true
notifications: []
labels: []
dependencies:
  require-all-stages-passing: false
  enabled-for-branches: true
  block-strategy: none
  plans: []
other:
  concurrent-build-plugin: system-default

---

version: 2
plan:
  key: AB-TP
plan-permissions:
  - users:
    - root
    permissions:
    - view
    - edit
    - build
    - clone
    - admin
    - view-configuration
  - roles:
    - logged-in
    - anonymous
    permissions:
    - view
...

```

A GitLab CI/CD `.gitlab-ci.yml` configuration with similar behavior would be:

```yaml
default:
  image: ruby:latest

stages:
  - default-stage

job1:
  stage: default-stage
  script:
    - ruby -v  # Print out ruby version for debugging
    - bundle config set --local deployment true  # Install dependencies into ./vendor/ruby
    - bundle install -j $(nproc)
    - rubocop
    - rspec spec
```

### Common Configurations

This section reviews some common Bamboo configurations and the GitLab CI/CD equivalents.

#### Workflow

Bamboo is structured differently compared to GitLab CI/CD. With GitLab, CI/CD can be enabled
in a project in a number of ways: by adding a `.gitlab-ci.yml` file to the project,
the existence of a Compliance pipeline in the group the project belongs to, or enabling AutoDevOps.
Pipelines are then triggered automatically, depending on rules or context, where AutoDevOps is used.

Bamboo is structured differently, [repositories need to be added](https://confluence.atlassian.com/bamboo0903/linking-to-source-code-repositories-1236445195.html)
to a Bamboo project, with authentication provided and [triggers](https://confluence.atlassian.com/bamboo0903/triggering-builds-1236445226.html)
are set. Repositories added to projects are available to all plans in the project.
Plans used for testing and building applications are called Build plans.

#### Build Plans

Build Plans in Bamboo are composed of Stages that run sequentially to build an application and generate artifacts where relevant. Build Plans require
a default repository attached to it or inherit linked repositories from its parent project.
Variables, triggers, and relationships between different plans can be defined at the plan level.

An example of a Bamboo build plan:

```yaml
version: 2
plan:
  project-key: SAMPLE
  name: Build Ruby App
  key: BUILD-APP

stages:
  - Test App:
      jobs:
        - Test Application
        - Perform Security checks
  - Build App:
      jobs:
        - Build Application

Test Application:
  tasks:
    - script:
        - # Run tests

Perform Security checks:
  tasks:
    - script:
        - # Run Security Checks

Build Application:
  tasks:
    - script:
        - # Run buils
```

In this example:

- Plan Specs include a YAML Spec version. Version 2 is the latest.
- The `project-key` links the plan to its parent project. The key is specified when creating the project.
- Plan `key` uniquely identifies the plan.

In GitLab CI/CD, a Bamboo Build plan is similar to the `.gitlab-ci.yml` file in a project,
which can include CI/CD scripts from other projects or templates.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
default:
  image: alpine:latest

stages:
  - test
  - build

test-application:
  stage: test
  script:
    - # Run tests

security-checks:
  stage: test
  script:
    - # Run Security Checks

build-application:
  stage: build
  script:
    - # Run builds
```

#### Container Images

Builds and deployments are run by default on the Bamboo agent's native operating system,
but can be configured to run in containers. To make jobs run in a container, Bamboo uses
the `docker` keyword at the plan or job level.

For example, in a Bamboo build plan:

```yaml
version: 2
plan:
  project-key: SAMPLE
  name: Build Ruby App
  key: BUILD-APP

docker: alpine:latest

stages:
  - Build App:
      jobs:
        - Build Application

Build Application:
  tasks:
    - script:
        - # Run builds
  docker:
    image: alpine:edge
```

In GitLab CI/CD, you only need the `image` keyword.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
default:
  image: alpine:latest

stages:
  - build

build-application:
  stage: build
  script:
    - # Run builds
  image:
    name: alpine:edge
```

#### Variables

Bamboo has the following types of [variables](https://confluence.atlassian.com/bamboo/bamboo-variables-289277087.html)
based on scope:

- Build-specific variables which are evaluated at build time. For example `${bamboo.planKey}`.
- System variables inherited from the Bamboo instance or system environment.
- Global variables defined for the entire instance and accessible to every plan.
- Project variables specific to a project and accessible by plans in the same project.
- Plan variables specific to a plan.

You can access variables in Bamboo using the format `${system.variableName}` for System variables
and `${bamboo.variableName}` for other types of variables. When using a variable in a script task,
the full stops, are converted to underscores, `${bamboo.variableName}` becomes `$bamboo_variableName`.

In GitLab, you can define [CI/CD variables](../variables/_index.md) at these levels:

- Instance
- Group
- Project
- In the `.gitlab-ci.yml` file as default variables for all jobs
- In the `.gitlab-ci.yml` file in individual jobs

Like Bamboo's System and Global variables, GitLab has [predefined CI/CD variables](../variables/predefined_variables.md)
that are available to every job.

Defining variables in CI/CD scripts is similar in both Bamboo and GitLab.

For example, in a Bamboo build plan:

```yaml
version: 2
# ...
variables:
  username: admin
  releaseType: milestone

Default job:
  tasks:
    - script: echo '$bamboo_username is the DRI for $bamboo_releaseType'
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables:
    JOB_VAR: "A job variable"
  script:
    - echo "Variables are '$DEFAULT_VAR' and '$JOB_VAR'"
```

In GitLab CI/CD, variables are accessed like regular Shell script variables. For example, `$VARIABLE_NAME`.

#### Jobs & Tasks

In both GitLab and Bamboo, jobs in the same stage run in parallel, except where there is a dependency
that needs to be met before a job runs.

The number of jobs that can run in Bamboo depends on availability of Bamboo agents
and Bamboo license Size. With [GitLab CI/CD](../jobs/_index.md), the number of parallel
jobs depends on the number of runners integrated with the GitLab instance and the
concurrency set in the runners.

In Bamboo, Jobs are composed of [Tasks](https://confluence.atlassian.com/bamboo/configuring-tasks-289277036.html),
which can be:

- A set of commands run as a [script](https://confluence.atlassian.com/bamboo/script-289277046.html)
- Predefined tasks like source code checkout, artifact download, and other tasks available in the
  Atlassian [tasks marketplace](https://marketplace.atlassian.com/addons/app/bamboo).

For example, in a Bamboo build plan:

```yaml
version: 2
#...

Default Job:
  key: JOB1
  tasks:
  - checkout:
      force-clean-build: false
      description: Checkout Default Repository
  - script:
      interpreter: SHELL
      scripts:
        - |-
          ruby -v
          bundle config set --local deployment true
          bundle install -j $(nproc)
      description: run bundler
other:
  concurrent-build-plugin: system-default
```

The equivalent of Tasks in GitLab is the `script`, which specifies the commands
for the runner to execute.

For example, in a GitLab CI/CD `.gitlab-ci.yml` file:

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - ruby -v
    - bundle config set --local deployment true
    - bundle install -j $(nproc)
```

With GitLab, you can use [CI/CD templates](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/lib/gitlab/ci/templates)
and [CI/CD components](../components/_index.md) to compose your pipelines without the need to write
everything yourself.

#### Conditionals

In Bamboo, every task can have conditions that determine if a task runs.

For example, in a Bamboo build plan:

```yaml
version: 2
# ...
tasks:
  - script:
      interpreter: SHELL
      scripts:
        - echo "Hello"
      conditions:
        - variable:
            equals:
              planRepository.branch: development
```

With GitLab, this can be done with the `rules` keyword to [control when jobs run](../jobs/job_control.md) in GitLab CI/CD.

For example, in a GitLab CI/CD `.gitlab-ci.yml` file:

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME = development
```

#### Triggers

Bamboo has a number of options for [triggering builds](https://confluence.atlassian.com/bamboo/triggering-builds-289276897.html),
which can be based on code changes, a schedule, the outcomes of other plans, or on demand.
A plan can be configured to periodically poll a project for new changes,
as shown below.

For example, in a Bamboo build plan:

```yaml
version: 2
#...
triggers:
  - polling:
      period: '180'
```

GitLab CI/CD pipelines can be triggered based on code change, on schedule, or triggered by
other jobs or API calls. GitLab CI/CD pipelines do not need to use polling, but can be triggered
on schedule as well.

You can configure when pipelines themselves run with the [`workflow` keyword](../yaml/workflow.md),
and `rules`.

For example, in a GitLab CI/CD `.gitlab-ci.yml` file:

```yaml
workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```

#### Artifacts

You can define Job artifacts using the `artifacts` keyword in both GitLab and Bamboo.

For example, in a Bamboo build plan:

```yaml
version: 2
# ...
  artifacts:
    -
      name: Test Reports
      location: target/reports
      pattern: '*.xml'
      required: false
      shared: false
    -
      name: Special Reports
      location: target/reports
      pattern: 'special/*.xml'
      shared: true
```

In this example, artifacts are defined with a name, location, and pattern. You can also share the artifacts with other jobs and plans or define jobs that subscribe to the artifact.

`artifact-subscriptions` is used to access artifacts from another job in the same plan,
for example:

```yaml
Test app:
  artifact-subscriptions:
    -
      artifact: Test Reports
      destination: deploy
```

`artifact-download` is used to access artifacts from jobs in a different plan, for example:

```yaml
version: 2
# ...
  tasks:
    - artifact-download:
        source-plan: PROJECTKEY-PLANKEY
```

You need to provide the key of the plan you are downloading artifacts from in the `source-plan` keyword.

In GitLab, all [artifacts](../jobs/job_artifacts.md) from completed jobs in earlier
stages are downloaded by default.

For example, in a GitLab CI/CD `.gitlab-ci.yml` file:

```yaml
stages:
  - build

pdf:
  stage: build
  script: #generate XML reports
  artifacts:
    name: "test-report-files"
    untracked: true
    paths:
      - target/reports
```

In this example:

- The name of the artifact is specific explicitly, but you can make it dynamic by using a CI/CD variable.
- The `untracked` keyword sets the artifact to also include Git untracked files,
  along with those specified explicitly with `paths`.

#### Caching

In Bamboo, [Git caches](https://confluence.atlassian.com/bamkb/how-stored-git-caches-speed-up-builds-690848923.html)
can be used to speed up builds. Git caches are configured in Bamboo administration settings
and are stored either on the Bamboo server or remote agents.

GitLab supports both Git Caches and Job cache. [Caches](../caching/_index.md) are defined per job
using the `cache` keyword.

For example, in a GitLab CI/CD `.gitlab-ci.yml` file:

```yaml
test-job:
  stage: build
  cache:
    - key:
        files:
          - Gemfile.lock
      paths:
        - vendor/ruby
    - key:
        files:
          - yarn.lock
      paths:
        - .yarn-cache/
  script:
    - bundle config set --local path 'vendor/ruby'
    - bundle install
    - yarn install --cache-folder .yarn-cache
    - echo Run tests...
```

#### Deployment Projects

Bamboo has [Deployments project](https://confluence.atlassian.com/bamboo/deployment-projects-338363438.html),
which link to Build plans to track, fetch, and deploy artifacts to [deployment environments](https://confluence.atlassian.com/bamboo0903/creating-a-deployment-environment-1236445634.html).

When creating a project you link it to a build plan, specify the deployment environment
and the tasks to perform the deployments. A [deployment task](https://confluence.atlassian.com/bamboo0903/tasks-for-deployment-environments-1236445662.html)
can either be a script or a Bamboo task from the Atlassian marketplace.

For example in a Deployment project Spec:

```yaml
version: 2

deployment:
  name: Deploy ruby app
  source-plan: build-app

release-naming: release-1.0

environments:
  - Production

Production:
  tasks:
    - # scripts to deploy app to production
    - ./.ci/deploy_prod.sh
```

In GitLab CI/CD, You can create a [deployment job](../jobs/_index.md#deployment-jobs)
that deploys to an [environment](../environments/_index.md) or creates a [release](../../user/project/releases/_index.md).

For example, in a GitLab CI/CD `.gitlab-ci.yml` file:

```yaml
deploy-to-production:
  stage: deploy
  script:
    - # Run Deployment script
    - ./.ci/deploy_prod.sh
  environment:
    name: production
```

To create release instead, use the [`release`](../yaml/_index.md#release)
keyword with the [release-cli](https://gitlab.com/gitlab-org/release-cli/-/tree/master/docs)
tool to create releases for [Git tags](../../user/project/repository/tags/_index.md).

For example, in a GitLab CI/CD `.gitlab-ci.yml` file:

```yaml
release_job:
  stage: release
  image: registry.gitlab.com/gitlab-org/release-cli:latest
  rules:
    - if: $CI_COMMIT_TAG                  # Run this job when a tag is created manually
  script:
    - echo "Building release version"
  release:
    tag_name: $CI_COMMIT_TAG
    name: 'Release $CI_COMMIT_TAG'
    description: 'Release created using the release-cli.'
```

### Security Scanning features

Bamboo relies on third-party tasks provided in the Atlassian Marketplace to run security scans.
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

Secrets management in Bamboo is usually handled using [Shared credentials](https://confluence.atlassian.com/bamboo/shared-credentials-424313357.html),
or via third-party applications from the Atlassian market place.

For secrets management in GitLab, you can use one of the supported integrations
for an external service. These services securely store secrets outside of your GitLab project,
though you must have a subscription for the service:

- [HashiCorp Vault](../secrets/hashicorp_vault.md)
- [Azure Key Vault](../secrets/azure_key_vault.md)
- [Google Cloud Secret Manager](../secrets/gcp_secret_manager.md)

GitLab also supports [OIDC authentication](../secrets/id_token_authentication.md)
for other third party services that support OIDC.

Additionally, you can make credentials available to jobs by storing them in CI/CD variables, though secrets
stored in plain text are susceptible to accidental exposure, [the same as in Bamboo](https://confluence.atlassian.com/bamboo/bamboo-specs-encryption-970268127.html).
You should always store sensitive information in [masked](../variables/_index.md#mask-a-cicd-variable)
and [protected](../variables/_index.md#protect-a-cicd-variable) variables, which mitigates
some of the risk.

Also, never store secrets as variables in your `.gitlab-ci.yml` file, which is public to all
users with access to the project. Storing sensitive information in variables should
only be done in [the project, group, or instance settings](../variables/_index.md#define-a-cicd-variable-in-the-ui).

Review the [security guidelines](../variables/_index.md#cicd-variable-security) to improve
the safety of your CI/CD variables.

### Migration Plan

The following list of recommended steps was created after observing organizations
that were able to quickly complete this migration.

#### Create a Migration Plan

Before starting a migration you should create a [migration plan](plan_a_migration.md)
to make preparations for the migration. For a migration from Bamboo, ask yourself
the following questions in preparation:

- What Bamboo Tasks are used by jobs in Bamboo today?
  - Do you know what these Tasks do exactly?
  - Do any Task wrap a common build tool? For example, Maven, Gradle, or NPM?
- What is installed on the Bamboo agents?
- Are there any shared libraries in use?
- How are you authenticating from Bamboo? Are you using SSH keys, API tokens, or other secrets?
- Are there other projects that you need to access from your pipeline?
- Are there credentials in Bamboo to access outside services? For example Ansible Tower,
  Artifactory, or other Cloud Providers or deployment targets?

#### Prerequisites

Before doing any migration work, you should first:

1. Get familiar with GitLab.
   - Read about the [key GitLab CI/CD features](../_index.md).
   - Follow tutorials to create [your first GitLab pipeline](../quick_start/_index.md)
     and [more complex pipelines](../quick_start/tutorial.md) that build, test, and deploy
     a static site.
   - Review the [CI/CD YAML syntax reference](../yaml/_index.md).
1. Set up and configure GitLab.
1. Test your GitLab instance.
   - Ensure [runners](../runners/_index.md) are available, either by using shared GitLab.com runners or installing new runners.

#### Migration Steps

1. Migrate projects from your SCM solution to GitLab.
   - (Recommended) You can use the available [importers](../../user/project/import/_index.md)
     to automate mass imports from external SCM providers.
   - You can [import repositories by URL](../../user/project/import/repo_by_url.md).
1. Create a `.gitlab-ci.yml` file in each project.
1. Export your Bamboo Projects/Plans as YAML Spec
1. Migrate Bamboo YAML Spec configuration to GitLab CI/CD jobs and configure them to show results directly in merge requests.
1. Migrate deployment jobs by using [cloud deployment templates](../cloud_deployment/_index.md),
   [environments](../environments/_index.md), and the [GitLab agent for Kubernetes](../../user/clusters/agent/_index.md).
1. Check if any CI/CD configuration can be reused across different projects, then create
   and share CI/CD templates.
1. Check the [pipeline efficiency documentation](../pipelines/pipeline_efficiency.md)
   to learn how to make your GitLab CI/CD pipelines faster and more efficient.

If you have questions that are not answered here, the [GitLab community forum](https://forum.gitlab.com/)
can be a great resource.
