---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: End-to-end test pipelines
---

## `e2e:test-on-cng`

The `e2e:test-on-cng` child pipeline runs tests against a [Cloud Native GitLab](https://gitlab.com/gitlab-org/build/CNG) installation.
Unlike `review-apps`, this pipeline uses a local [kind](https://github.com/kubernetes-sigs/kind) Kubernetes cluster.

Deployment is managed by the [`cng`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/gems/gitlab-cng/README.md)
orchestrator tool, which you can also use to locally recreate CI/CD deployments.

The `e2e:test-on-cng` child pipeline is executed in merge requests and is part of pre-merge validation lifecycle. If any test fails, you can't merge introduced
code changes.

### Setup

The pipeline setup consists of several jobs in the main GitLab pipeline:

- `compile-production-assets` and `build-assets-image` jobs are responsible for compiling frontend assets which are required
  by [CNG](https://gitlab.com/gitlab-org/build/CNG-mirror) build pipeline.
- `e2e-test-pipeline-generate` job is responsible for generating `e2e:test-on-cng` child pipeline

### child pipeline jobs

The child pipeline consists of several stages that support E2E test execution.

#### .pre

- `build-cng-env` job is responsible for setting up all environment variables for [CNG](https://gitlab.com/gitlab-org/build/CNG-mirror) downstream pipeline
- `build-cng` job triggers `CNG` downstream pipeline which is responsible for building all necessary images

#### test

Jobs in `test` stage perform following actions:

1. local k8s cluster setup using [`kind`](https://github.com/kubernetes-sigs/kind)
1. GitLab installation using official [`helm` chart](https://gitlab.com/gitlab-org/charts/gitlab)
1. E2E test execution against performed deployment

#### report

This stage is responsible for [allure test report](_index.md#allure-report) generation as well as test metrics upload.

### Debugging

To help with debugging:

- Each test job prints a list of arguments that you can pass to the [`cng`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/gems/gitlab-cng/README.md)
  orchestrator to exactly recreate the same deployment for local debugging.
- Cluster events log and all pod logs are saved in E2E test job artifacts.
- `cng` orchestrator automatically outputs all cluster events with errors in the case of failed deployment.

## `e2e:test-on-omnibus`

The `e2e:test-on-omnibus` child pipeline is the main executor of E2E testing for the GitLab platform. The pipeline definition has several dynamic
components to reduce the number of tests being executed in merge request pipelines.

### Setup

Pipeline setup consists of:

- The `e2e-test-pipeline-generate` job in the `prepare` stage of the main GitLab pipeline.
- The `e2e:test-on-omnibus` job in the `qa` stage, which triggers the child pipeline that is responsible for building the `omnibus` package and
  running E2E tests.

#### e2e-test-pipeline-generate

This job consists of two components that implement selective test execution:

- The [`detect_changes`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/tasks/ci.rake) Rake task determines which e2e specs should be executed
  in a particular merge request pipeline. This task analyzes changes in a particular merge request and determines which specs must be executed.
  Based on that, a `dry-run` of every [scenario](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/qa/scenario/test) executes and determines if a
  scenario contains any executable tests. Selective test execution uses [these criteria](_index.md#selective-test-execution) to determine which specific
  tests to execute.
- [`generate-e2e-pipeline`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/generate-e2e-pipeline) is executed, which generates a child
  pipeline YAML definition file with appropriate environment variables.

#### child pipeline jobs

E2E test execution pipeline consists of several stages which all support execution of E2E tests.

##### .pre

This stage is responsible for the following tasks:

- Fetching `knapsack` reports that support [parallel test execution](_index.md#test-parallelization).
- Triggering downstream pipeline which builds the [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab) Docker image.

##### test

This stage runs e2e tests against different types of GitLab configurations. The number of jobs executed is determined dynamically by
[`e2e-test-pipeline-generate`](test_pipelines.md#e2e-test-pipeline-generate) job.

##### report

This stage is responsible for [allure test report](_index.md#allure-report) generation.

## `e2e:test-on-gdk`

The `e2e:test-on-gdk` child pipeline supports development of the GitLab platform by providing feedback to engineers on
end-to-end test execution faster than via `e2e:test-on-omnibus`.

This is achieved by running tests against the [GitLab Development Kit](https://gitlab.com/gitlab-org/gitlab-development-kit) (GDK),
which can be built and installed in less time than when testing against [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab).
The trade-off is that Omnibus GitLab can be used to deploy a production installation, whereas the GDK is a development
environment. Tests that run against the GDK might not catch bugs that depend on part of the process of preparing GitLab
to run in a production environment, including pre-compiling assets, assigning configuration defaults as part of an official
installation package, deploying GitLab services to multiple servers, and more. On the other hand, engineers who use the
GDK day-to-day can benefit from automated tests catching bugs that only appear on the GDK.

### Setup

The pipeline setup consists of several jobs in the main GitLab pipeline:

- The [`e2e-test-pipeline-generate` job](https://gitlab.com/gitlab-org/gitlab/-/blob/9456299b995084bfceb8bc6d082229c0198a0f72/.gitlab/ci/setup.gitlab-ci.yml#L158)
  in the `prepare` stage. This is the same job as in the `e2e:test-on-omnibus` pipeline.
- The [`build-gdk-image` job](https://gitlab.com/gitlab-org/gitlab/-/blob/07504c34b28ac656537cd60810992aa15e9e91b8/.gitlab/ci/build-images.gitlab-ci.yml#L32)
  in the `build-images` stage.
- The `e2e:test-on-gdk` trigger job in the `qa` stage, which triggers the child pipeline that runs E2E tests.

#### `build-gdk-image`

[This job](https://gitlab.com/gitlab-org/gitlab/-/blob/07504c34b28ac656537cd60810992aa15e9e91b8/.gitlab/ci/build-images.gitlab-ci.yml#L32)
uses the code from the merge request to build a Docker image that can be used in test jobs to launch a GDK instance in a container. The image is pushed to the container registry.

The job also runs in pipelines on the default branch to build a base image that includes the GDK and GitLab components.
This avoids building the entire image from scratch in merge requests. However, if the merge request includes changes to
[certain GitLab components or code](https://gitlab.com/gitlab-org/gitlab/-/blob/24109c1a7ae1f29d4f6f1aeba3a13cbd8ea0e8e6/.gitlab/ci/rules.gitlab-ci.yml#L911)
the job will rebuild the base image before building the image that will be used in the test jobs.

#### child pipeline jobs

Like the `e2e:test-on-omnibus` pipeline, the `e2e:test-on-gdk` pipeline consists of several stages that support
execution of E2E tests.

##### .pre

This stage is responsible for fetching `knapsack` reports that support [parallel test execution](_index.md#test-parallelization).

##### test

This stage runs e2e tests against different types of GitLab configurations. The number of jobs executed is determined dynamically by the
[`e2e-test-pipeline-generate`](test_pipelines.md#e2e-test-pipeline-generate) job.

Each job starts a container from the GDK Docker image created in the `build-gdk-image` job, and then executes the end-to-end
tests against the GDK instance running in the container.

##### report

This stage is responsible for [allure test report](_index.md#allure-report) generation.

## Test Licenses

Please see the [Test Licenses runbook](https://gitlab-org.gitlab.io/quality/runbooks/test_licenses/) for more information on the licenses used by these pipelines.

## Adding new jobs to E2E test pipelines

E2E test pipelines use dynamic scaling of jobs based on their runtime. To create a mapping between job definitions in pipeline definition YAML files and
a particular test scenario, `scenario` classes are used. These classes are located in `qa/qa/scenario` folder.

A typical job definition in one of the e2e test pipeline definition YAML files would look like:

```yaml
my-new-test-job:
  ...
  variables:
    QA_SCENARIO: Test::Integration::MyNewTestScenario
```

In this example:

- `QA_SCENARIO: Test::Integration::MyNewTestScenario`: name of the scenario class that is passed to the `qa/bin/qa` test execution script. While the full class
  name would be `QA::Scenario::Test:Integration::MyNewTestScenario`, `QA::Scenario` is omitted to have shorted definitions.

Considering example above, perform the following steps to create a new job:

1. Create a new scenario `my_new_job.rb` in the [`integration`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/qa/scenario/test/integration) directory
   of the [`e2e`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa) test framework. The scenario class should define a pipeline mapping that couples the
   scenario to a specific job in a specific pipeline type. If job was added to the [test-on-cng](#e2etest-on-cng) pipeline, this scenario would define RSpec
   tags that should be executed and pipeline mapping:

   ```ruby
   module QA
     module Scenario
       module Test
         module Integration
           class MyNewJob < Test::Instance::All
             tags :some_special_tag

             pipeline_mappings test_on_cng: %w[my-new-test-job]
           end
         end
       end
     end
   end
   ```

1. Add the new job definition in the [`main.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/test-on-cng/main.gitlab-ci.yml)
   pipeline definition:

   ```yaml
   my-new-test-job:
     extends:
       - .cng-test
     variables:
       QA_SCENARIO: Test::Integration::MyNewTestScenario
   ```

Such a definition ensures that `my-new-test-job` has automatic parallel job scaling based on predefined runtime threshold.
