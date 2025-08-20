---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from Bamboo
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

You can migrate from Atlassian Bamboo to GitLab CI/CD by converting Bamboo Specs YAML
configurations exported from the Bamboo UI or stored in Spec repositories.

## Key migration considerations

| Configuration aspect  | Bamboo                             | GitLab CI/CD                         | Migration impact |
| --------------------- | ---------------------------------- | ------------------------------------ | ---------------- |
| Configuration files   | Bamboo Specs (Java or YAML)        | `.gitlab-ci.yml` file                | Convert Specs to GitLab YAML syntax |
| Variable syntax       | `${bamboo.variableName}`           | `$VARIABLE_NAME`                     | Update all variable references in scripts |
| Execution environment | Agents (local or remote)           | Runners with executors               | Install and configure runners |
| Artifact sharing      | Named artifacts with subscriptions | Automatic inheritance between stages | Simplify artifact configuration |
| Deployments           | Separate deployment projects       | Deployment jobs with environments    | Combine build and deploy in single pipeline |

## Configuration examples

### Bamboo Specs export

The following examples show a Bamboo Specs YAML export from the UI and its GitLab CI/CD equivalent.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo organizes builds through a nested hierarchy where projects contain multiple plans,
plans define stages and jobs, and jobs execute individual tasks.
Projects serve as containers for shared resources like variables, credentials,
and repository connections that multiple plans can access.

Bamboo Specs exports from the UI include this complete hierarchy plus administrative metadata like permissions,
notifications, and project settings.

When reviewing your export, focus on these migration-critical elements:

- Jobs and tasks: The actual build commands and scripts
- Stage definitions: Sequential execution order and dependencies
- Variables and artifacts: Data and files shared between jobs
- Triggers and conditions: Rules that determine when builds run

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

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD eliminates the nested complexity. Instead each repository contains a single `.gitlab-ci.yml` file that defines all stages and jobs.

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

{{< /tab >}}

{{< /tabs >}}

### Jobs and tasks

In both GitLab and Bamboo, jobs in the same stage run in parallel, except where there is
a dependency that needs to be met before a job runs.

The number of jobs that can run in Bamboo depends on availability of Bamboo agents
and Bamboo license size.

With GitLab CI/CD, the number of parallel jobs depends on the number
of runners integrated with the GitLab instance and the concurrency set in the runners.

{{< tabs >}}

{{< tab title="Bamboo" >}}

In Bamboo, jobs are composed of tasks, which can be a set of commands run as a script
or predefined tasks like source code checkout, artifact download, and other tasks available
in the Atlassian tasks marketplace.

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

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

The equivalent of tasks in GitLab is the `script`, which specifies the commands
for the runner to execute. You can use CI/CD templates and CI/CD components to compose
your pipelines without the need to write everything yourself.

```yaml
job1:
  script: "bundle exec rspec"

job2:
  script:
    - ruby -v
    - bundle config set --local deployment true
    - bundle install -j $(nproc)
```

{{< /tab >}}

{{< /tabs >}}

### Container images

The following examples show how the Bamboo `docker` keyword translates to the GitLab `image` keyword.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Builds and deployments run by default on the Bamboo agent's native operating system,
but can be configured to run in containers using the `docker` keyword:

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

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

In GitLab CI/CD, you only need the `image` keyword.

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

{{< /tab >}}

{{< /tabs >}}

### Variables

The following examples show the syntax differences for defining and accessing variables.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo has different variable types with different access patterns.
System variables use `${system.variableName}` and other variables use `${bamboo.variableName}`.

In script tasks, dots are converted to underscores. For example, `${bamboo.variableName}` becomes `$bamboo_variableName`.

```yaml
variables:
  username: admin
  releaseType: milestone

Default job:
  tasks:
    - script: echo '$bamboo_username is the DRI for $bamboo_releaseType'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

In GitLab CI/CD, variables are accessed like regular Shell script variables using `$VARIABLE_NAME`.
Like system and global variables in Bamboo, GitLab has predefined CI/CD variables that are
available to every job.

```yaml
variables:
  DEFAULT_VAR: "A default variable"

job1:
  variables:
    JOB_VAR: "A job variable"
  script:
    - echo "Variables are '$DEFAULT_VAR' and '$JOB_VAR'"
```

{{< /tab >}}

{{< /tabs >}}

### Conditions and triggers

These examples show how Bamboo conditions and triggers convert to GitLab rules.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo has various options for triggering builds, which can be based on code changes, a schedule,
the outcomes of other plans, or on demand. A plan can be configured to periodically poll
a project for new changes.

```yaml
tasks:
  - script:
      scripts:
        - echo "Hello"
      conditions:
        - variable:
            equals:
              planRepository.branch: development

triggers:
  - polling:
      period: '180'
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

GitLab CI/CD pipelines are triggered based on code changes, schedules, or API calls.
Pipelines do not use polling.

```yaml
job:
  script: echo "Hello, Rules!"
  rules:
    - if: $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME = development

workflow:
  rules:
    - changes:
        - .gitlab/**/**.md
      when: never
```

{{< /tab >}}

{{< /tabs >}}

### Artifacts

You can define job artifacts using the `artifacts` keyword in both GitLab and Bamboo.

{{< tabs >}}

{{< tab title="Bamboo" >}}

In Bamboo, artifacts are defined with a name, location, and pattern. You can share the artifacts
with other jobs and plans or define jobs that subscribe to the artifact.

`artifact-subscriptions` is used to access artifacts from another job in the same plan,
and `artifact-download` is used to access artifacts from jobs in a different plan.

```yaml
version: 2
# ...
Build:
  # ...
  artifacts:
    - name: Test Reports
      location: target/reports
      pattern: '*.xml'
      required: false
      shared: false
    - name: Special Reports
      location: target/reports
      pattern: 'special/*.xml'
      shared: true

Test app:
  artifact-subscriptions:
    - artifact: Test Reports
      destination: deploy

# ...
Build:
  # ...
  tasks:
    - artifact-download:
        source-plan: PROJECTKEY-PLANKEY
```

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

In GitLab, all artifacts from completed jobs in earlier stages are downloaded by default.

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

- The name of the artifact is specified explicitly, but you can make it dynamic by using
  a CI/CD variable.
- The `untracked` keyword sets the artifact to also include Git untracked files,
  along with those specified explicitly with `paths`.

{{< /tab >}}

{{< /tabs >}}

### Caching

In Bamboo, Git caches can be used to speed up builds. Git caches are configured in Bamboo
administration settings and are stored either on the Bamboo server or remote agents.

GitLab supports both Git caches and job cache. Caches are defined for each job using the `cache` keyword:

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

### Deployments

The following examples show how to convert Bamboo deployment projects to GitLab deployment jobs.

{{< tabs >}}

{{< tab title="Bamboo" >}}

Bamboo has deployment projects, which link to build plans to track, fetch, and deploy artifacts
to deployment environments. When creating a project you link it to a build plan, specify
the deployment environment and the tasks to perform the deployments.

```yaml
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

{{< /tab >}}

{{< tab title="GitLab CI/CD" >}}

In GitLab CI/CD, you can create a deployment job that deploys to an environment or creates a release.

```yaml
deploy-to-production:
  stage: deploy
  script:
    - # Run Deployment script
    - ./.ci/deploy_prod.sh
  environment:
    name: production
```

To create a release instead, use the `release` keyword with the release-cli tool to create
releases for Git tags:

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

{{< /tab >}}

{{< /tabs >}}

## Security scanning

Bamboo relies on third-party tasks provided in the Atlassian Marketplace to run security scans.

GitLab provides security scanners to detect vulnerabilities in all parts of the SDLC.
You can add these scanners in GitLab using templates, for example to add SAST scanning
to your pipeline:

```yaml
include:
  - template: Jobs/SAST.gitlab-ci.yml
```

You can customize the behavior of security scanners by using CI/CD variables.

## Secrets management

Secrets management in Bamboo is handled using shared credentials, or with third-party applications
from the Atlassian marketplace.

For secrets management in GitLab, you can use supported integrations for external services.
These services securely store secrets outside of your GitLab project, though you must have
a subscription for the service.

GitLab also supports OIDC authentication for other third-party services that support OIDC.

Additionally, you can make credentials available to jobs by storing them in CI/CD variables,
though secrets stored in plain text are susceptible to accidental exposure.
You should always store sensitive information in masked and protected variables,
which mitigates some of the risk.

{{< alert type="note" >}}

Never store secrets as variables in your `.gitlab-ci.yml` file, which is public to all
users with access to the project. Storing sensitive information in variables should
only be done in the project, group, or instance settings.

{{< /alert >}}

## Create a migration plan

Before starting your migration, create a [migration plan](plan_a_migration.md) and answer these questions:

- What Bamboo Tasks are used by jobs today and what do they do?
- Do any tasks wrap common build tools like Maven, Gradle, or NPM?
- What software is installed on Bamboo agents?
- How are you authenticating from Bamboo (SSH keys, API tokens, or other secrets)?
- Are there credentials in Bamboo to access outside services?
- Are there shared libraries or templates in use?

## Migrate from Bamboo to GitLab CI/CD

Prerequisites:

- You must have a GitLab instance set up and configured.
- You must have [runners](../runners/_index.md) available.

To migrate from Bamboo:

1. Audit your Bamboo configuration:
   - Export your Bamboo projects/plans as a YAML Spec from the Bamboo UI.
   - List all Bamboo tasks used in your jobs (for example, Maven, Docker, SCP).
   - Document software versions installed on each Bamboo agent.
   - Identify all shared credentials and their usage.

1. Migrate your source code repositories to GitLab:
   - Use the available [importers](../../user/project/import/_index.md) to automate mass imports
     from external SCM providers.
   - [Import repositories by URL](../../user/project/import/repo_by_url.md) for individual repositories.

1. Set up GitLab runners with equivalent software:
   - Install the same software versions that exist on your Bamboo agents.
   - For complex agent setups, create custom Docker images with your required tools.
   - Test that runners can execute your build commands successfully.

1. Convert Bamboo Specs to `.gitlab-ci.yml` files:
   - Replace Bamboo plan structure with GitLab stages and jobs.
   - Convert `${bamboo.variableName}` syntax to `$VARIABLE_NAME`.
   - Replace Bamboo-specific variables like `${bamboo.planKey}` with GitLab equivalents
     like `$CI_PIPELINE_ID`.
   - Remove Bamboo checkout tasks (GitLab handles this automatically).

1. Migrate artifact handling:
   - Remove Bamboo `artifact-subscriptions` and `artifact-download` configurations.
   - Use automatic artifact inheritance between stages.
   - Update artifact paths to match your GitLab job structure.

1. Convert Bamboo deployment projects:
   - Move deployment tasks from separate Bamboo deployment projects into your main
     `.gitlab-ci.yml` file.
   - Replace Bamboo environments with GitLab [environments](../environments/_index.md).
   - Use [cloud deployment templates](../cloud_deployment/_index.md) for common deployment patterns.
   - Configure the [GitLab agent for Kubernetes](../../user/clusters/agent/_index.md)
     if deploying to Kubernetes.

1. Migrate secrets and credentials:
   - Use [external secrets integrations](../secrets/_index.md) or store credentials as masked
     and protected CI/CD variables.

1. Test and optimize your migrated pipelines:
   - Run test pipelines to verify functionality.
   - Add merge request integration to display pipeline results.
   - Optimize pipeline performance and create reusable templates.

## Related topics

- [Getting started guide](../_index.md)
- [CI/CD YAML syntax reference](../yaml/_index.md)
- [GitLab CI/CD variables](../variables/_index.md)
- [Pipeline efficiency](../pipelines/pipeline_efficiency.md)
