---
stage: Verify
group: Pipeline Authoring
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrating from GitHub Actions
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

If you're migrating from GitHub Actions to GitLab CI/CD, you are able to create CI/CD
pipelines that replicate and enhance your GitHub Action workflows.

## Key Similarities and Differences

GitHub Actions and GitLab CI/CD are both used to generate pipelines to automate building, testing,
and deploying your code. Both share similarities including:

- CI/CD functionality has direct access to the code stored in the project repository.
- Pipeline configurations written in YAML and stored in the project repository.
- Pipelines are configurable and can run in different stages.
- Jobs can each use a different container image.

Additionally, there are some important differences between the two:

- GitHub has a marketplace for downloading 3rd-party actions, which might require additional support or licenses.
- GitLab Self-Managed supports both horizontal and vertical scaling, while
  GitHub Enterprise Server only supports vertical scaling.
- GitLab maintains and supports all features in house, and some 3rd-party integrations
  are accessible through templates.
- GitLab provides a built-in container registry.
- GitLab has native Kubernetes deployment support.
- GitLab provides granular security policies.

## Comparison of features and concepts

Many GitHub features and concepts have equivalents in GitLab that offer the same
functionality.

### Configuration file

GitHub Actions can be configured with a [workflow YAML file](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#understanding-the-workflow-file).
GitLab CI/CD uses a `.gitlab-ci.yml` YAML file by default.

For example, in a GitHub Actions `workflow` file:

```yaml
on: [push]
jobs:
  hello:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Hello World"
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
stages:
  - hello

hello:
  stage: hello
  script:
    - echo "Hello World"
```

### GitHub Actions workflow syntax

A GitHub Actions configuration is defined in a `workflow` YAML file using specific keywords.
GitLab CI/CD has similar functionality, also usually configured with YAML keywords.

| GitHub    | GitLab         | Explanation |
|-----------|----------------|-------------|
| `env`     | `variables`    | `env` defines the variables set in a workflow, job, or step. GitLab uses `variables` to define [CI/CD variables](../variables/_index.md) at the global or job level. Variables can also be added in the UI. |
| `jobs`    | `stages`       | `jobs` groups together all the jobs that run in the workflow. GitLab uses `stages` to group jobs together. |
| `on`      | Not applicable | `on` defines when a workflow is triggered. GitLab is integrated tightly with Git, so SCM polling options for triggers are not needed, but can be configured per job if required. |
| `run`     | Not applicable | The command to execute in the job. GitLab uses a YAML array under the `script` keyword, one entry for each command to execute. |
| `runs-on` | `tags`         | `runs-on` defines the GitHub runner that a job must run on. GitLab uses `tags` to select a runner. |
| `steps`   | `script`       | `steps` groups together all the steps that run in a job. GitLab uses `script` to group together all the commands run in a job. |
| `uses`    | `include`      | `uses` defines what GitHub Action to be added to a `step`. GitLab uses `include` to add configuration from other files to a job. |

### Common configurations

This section goes over commonly used CI/CD configurations, showing how they can be converted
from GitHub Actions to GitLab CI/CD.

[GitHub Action workflows](https://docs.github.com/en/actions/learn-github-actions/understanding-github-actions#workflows)
generate automated CI/CD jobs that are triggered when certain event take place, for example
pushing a new commit. A GitHub Action workflow is a YAML file defined in the `.github/workflows`
directory located in the root of the repository. The GitLab equivalent is the
`.gitlab-ci.yml` configuration file, which also resides
in the repository's root directory.

#### Jobs

Jobs are a set of commands that run in a set sequence to achieve a particular result,
for example building a container or deploying to production.

For example, this GitHub Actions `workflow` builds a container then deploys it to production.
The jobs runs sequentially, because the `deploy` job depends on the `build` job:

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - run: apk update
      - run: go build -o bin/hello
      - uses: actions/upload-artifact@v3
        with:
          name: hello
          path: bin/hello
          retention-days: 7
  deploy:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: golang:alpine
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: hello
      - run: echo "Deploying to Staging"
      - run: scp bin/hello remoteuser@remotehost:/remote/directory
```

This example:

- Uses the `golang:alpine` container image.
- Runs a job for building code.
  - Stores build executable as artifact.
- Runs a second job to deploy to `staging`, which also:
  - Requires the build job to succeed before running.
  - Requires the commit target branch `staging`.
  - Uses the build executable artifact.

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
```

##### Parallel

In both GitHub and GitLab, Jobs run in parallel by default.

For example, in a GitHub Actions `workflow` file:

```yaml
on: [push]
jobs:
  python-version:
    runs-on: ubuntu-latest
    container: python:latest
    steps:
      - run: python --version
  java-version:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    container: openjdk:latest
    steps:
      - run: java -version
```

This example runs a Python job and a Java job in parallel, using different container images.
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

In both GitLab and GitHub you can use a matrix to run a job multiple times in parallel in a single pipeline,
but with different variable values for each instance of the job.

For example, in a GitHub Actions `workflow` file:

```yaml
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Building $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  test:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Testing $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
  deploy:
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploying $PLATFORM for $ARCH"
    strategy:
      matrix:
        platform: [linux, mac, windows]
        arch: [x64, x86]
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
    - echo "Deploying $PLATFORM for $ARCH"
```

#### Trigger

GitHub Actions requires you to add a trigger for your workflow. GitLab is integrated tightly with Git,
so SCM polling options for triggers are not needed, but can be configured per job if required.

Sample GitHub Actions configuration:

```yaml
on:
  push:
    branches:
      - main
```

The equivalent GitLab CI/CD configuration would be:

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == main'
```

Pipelines can also be [scheduled by using Cron syntax](../pipelines/schedules.md).

#### Container Images

With GitLab you can [run your CI/CD jobs in separate, isolated Docker containers](../docker/using_docker_images.md)
by using the [`image`](../yaml/_index.md#image) keyword.

For example, in a GitHub Actions `workflow` file:

```yaml
jobs:
  update:
    runs-on: ubuntu-latest
    container: alpine:latest
    steps:
      - run: apk update
```

In this example the `apk update` command runs in an `alpine:latest` container.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
update-job:
  image: alpine:latest
  script:
    - apk update
```

GitLab provides every project a [container registry](../../user/packages/container_registry/_index.md)
for hosting container images. Container images can be built and stored directly from
GitLab CI/CD pipelines.

For example:

```yaml
stages:
  - build

build-image:
  stage: build
  variables:
    IMAGE: $CI_REGISTRY_IMAGE/$CI_COMMIT_REF_SLUG:$CI_COMMIT_SHA
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE .
    - docker push $IMAGE
```

#### Variables

In GitLab, we use the `variables` keyword to define different [CI/CD variables](../variables/_index.md) at runtime.
Use variables when you need to reuse configuration data in a pipeline. You can define
variables globally or per job.

For example, in a GitHub Actions `workflow` file:

```yaml
env:
  NAME: "fern"

jobs:
  english:
    runs-on: ubuntu-latest
    env:
      Greeting: "hello"
    steps:
      - run: echo "$GREETING $NAME"
  spanish:
    runs-on: ubuntu-latest
    env:
      Greeting: "hola"
    steps:
      - run: echo "$GREETING $NAME"
```

In this example, variables provide different outputs for the jobs.

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
default:
  image: ubuntu-latest

variables:
  NAME: "fern"

english:
  variables:
    GREETING: "hello"
  script:
    - echo "$GREETING $NAME"

spanish:
  variables:
    GREETING: "hola"
  script:
    - echo "$GREETING $NAME"
```

Variables can also be set up through the GitLab UI, under CI/CD settings, where you can
[protect](../variables/_index.md#protect-a-cicd-variable) or [mask](../variables/_index.md#mask-a-cicd-variable)
the variables. Masked variables are hidden in job logs, while protected variables
can only be accessed in pipelines for protected branches or tags.

For example, in a GitHub Actions `workflow` file:

```yaml
jobs:
  login:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY: ${{ secrets.AWS_ACCESS_KEY }}
    steps:
      - run: my-login-script.sh "$AWS_ACCESS_KEY"
```

If the `AWS_ACCESS_KEY` variable is defined in the GitLab project settings, the equivalent
GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
login:
  script:
    - my-login-script.sh $AWS_ACCESS_KEY
```

Additionally, [GitHub Actions](https://docs.github.com/en/actions/learn-github-actions/contexts)
and [GitLab CI/CD](../variables/predefined_variables.md) provide built-in variables
which contain data relevant to the pipeline and repository.

#### Conditionals

When a new pipeline starts, GitLab checks the pipeline configuration to determine
which jobs should run in that pipeline. You can use the [`rules` keyword](../yaml/_index.md#rules)
to configure jobs to run depending on conditions like the status of variables, or the pipeline type.

For example, in a GitHub Actions `workflow` file:

```yaml
jobs:
  deploy_staging:
    if: contains( github.ref, 'staging')
    runs-on: ubuntu-latest
    steps:
      - run: echo "Deploy to staging server"
```

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

Runners are the services that execute jobs. If you are using GitLab.com, you can use the
[instance runner fleet](../runners/_index.md) to run jobs without provisioning your own self-managed runners.

Some key details about runners:

- Runners can be [configured](../runners/runners_scope.md) to be shared across an instance,
  a group, or dedicated to a single project.
- You can use the [`tags` keyword](../runners/configure_runners.md#control-jobs-that-a-runner-can-run)
  for finer control, and associate runners with specific jobs. For example, you can use a tag for jobs that
  require dedicated, more powerful, or specific hardware.
- GitLab has [autoscaling for runners](https://docs.gitlab.com/runner/configuration/autoscale.html).
  Use autoscaling to provision runners only when needed and scale down when not needed.

For example, in a GitHub Actions `workflow` file:

```yaml
linux_job:
  runs-on: ubuntu-latest
  steps:
    - run: echo "Hello, $USER"

windows_job:
  runs-on: windows-latest
  steps:
    - run: echo "Hello, %USERNAME%"
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
linux_job:
  stage: build
  tags:
    - linux-runners
  script:
    - echo "Hello, $USER"

windows_job:
  stage: build
  tags:
    - windows-runners
  script:
    - echo "Hello, %USERNAME%"
```

#### Artifacts

In GitLab, any job can use the [artifacts](../yaml/_index.md#artifacts) keyword to define a set
of artifacts to be stored when a job completes. [Artifacts](../jobs/job_artifacts.md) are files
that can be used in later jobs.

For example, in a GitHub Actions `workflow` file:

```yaml
on: [push]
jobs:
  generate_cat:
    steps:
      - run: touch cat.txt
      - run: echo "meow" > cat.txt
      - uses: actions/upload-artifact@v3
        with:
          name: cat
          path: cat.txt
          retention-days: 7
  use_cat:
    needs: [generate_cat]
    steps:
      - uses: actions/download-artifact@v3
        with:
          name: cat
      - run: cat cat.txt
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

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

#### Caching

A [cache](../caching/_index.md) is created when a job downloads one or more files and
saves them for faster access in the future. Subsequent jobs that use the same cache don't have to download the files again,
so they execute more quickly. The cache is stored on the runner and uploaded to S3 if
[distributed cache is enabled](https://docs.gitlab.com/runner/configuration/autoscale.html#distributed-runners-caching).

For example, in a GitHub Actions `workflow` file:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - run: echo "This job uses a cache."
    - uses: actions/cache@v3
      with:
        path: binaries/
        key: binaries-cache-$CI_COMMIT_REF_SLUG
```

The equivalent GitLab CI/CD `.gitlab-ci.yml` file would be:

```yaml
cache-job:
  script:
    - echo "This job uses a cache."
  cache:
    key: binaries-cache-$CI_COMMIT_REF_SLUG
    paths:
      - binaries/
```

#### Templates

In GitHub an Action is a set of complex tasks that need to be frequently repeated and is saved
to enable reuse without redefining a CI/CD pipeline. In GitLab the equivalent to an action would
be a the [`include` keyword](../yaml/includes.md), which allows you to [add CI/CD pipelines from other files](../yaml/includes.md),
including template files built into GitLab.

Sample GitHub Actions configuration:

```yaml
- uses: hashicorp/setup-terraform@v2.0.3
```

The equivalent GitLab CI/CD configuration would be:

```yaml
include:
  - template: Terraform.gitlab-ci.yml
```

In these examples, the `setup-terraform` GitHub action and the `Terraform.gitlab-ci.yml` GitLab template
are not exact matches. These two examples are just to show how complex configuration can be reused.

### Security Scanning features

GitLab provides a variety of [security scanners](../../user/application_security/_index.md)
out-of-the-box to detect vulnerabilities in all parts of the SLDC. You can add these features
to your GitLab CI/CD pipeline by using templates.

for example to add SAST scanning to your pipeline, add the following to your `.gitlab-ci.yml`:

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

For secrets management in GitLab, you can use one of the supported integrations
for an external service. These services securely store secrets outside of your GitLab project,
though you must have a subscription for the service:

- [HashiCorp Vault](../secrets/hashicorp_vault.md)
- [Azure Key Vault](../secrets/azure_key_vault.md)
- [Google Cloud Secret Manager](../secrets/gcp_secret_manager.md)

GitLab also supports [OIDC authentication](../secrets/id_token_authentication.md)
for other third party services that support OIDC.

Additionally, you can make credentials available to jobs by storing them in CI/CD variables, though secrets
stored in plain text are susceptible to accidental exposure. You should always store sensitive information
in [masked](../variables/_index.md#mask-a-cicd-variable) and [protected](../variables/_index.md#protect-a-cicd-variable)
variables, which mitigates some of the risk.

Also, never store secrets as variables in your `.gitlab-ci.yml` file, which is public to all
users with access to the project. Storing sensitive information in variables should
only be done in [the project, group, or instance settings](../variables/_index.md#define-a-cicd-variable-in-the-ui).

Review the [security guidelines](../variables/_index.md#cicd-variable-security) to improve
the safety of your CI/CD variables.

## Planning and Performing a Migration

The following list of recommended steps was created after observing organizations
that were able to quickly complete this migration.

### Create a Migration Plan

Before starting a migration you should create a [migration plan](plan_a_migration.md) to make preparations for the migration.

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

1. Migrate Projects from GitHub to GitLab:
   - (Recommended) You can use the [GitHub Importer](../../user/project/import/github.md)
     to automate mass imports from external SCM providers.
   - You can [import repositories by URL](../../user/project/import/repo_by_url.md).
1. Create a `.gitlab-ci.yml` in each project.
1. Migrate GitHub Actions jobs to GitLab CI/CD jobs and configure them to show results directly in merge requests.
1. Migrate deployment jobs by using [cloud deployment templates](../cloud_deployment/_index.md),
   [environments](../environments/_index.md), and the [GitLab agent for Kubernetes](../../user/clusters/agent/_index.md).
1. Check if any CI/CD configuration can be reused across different projects, then create
   and share [CI/CD templates](../../development/cicd/templates.md)
1. Check the [pipeline efficiency documentation](../pipelines/pipeline_efficiency.md)
   to learn how to make your GitLab CI/CD pipelines faster and more efficient.

### Additional Resources

- [Video: How to migrate from GitHub to GitLab including Actions](https://youtu.be/0Id5oMl1Kqs?feature=shared)
- [Blog: GitHub to GitLab migration the easy way](https://about.gitlab.com/blog/2023/07/11/github-to-gitlab-migration-made-easy/)

If you have questions that are not answered here, the [GitLab community forum](https://forum.gitlab.com/) can be a great resource.
