---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
---

# End-to-end test pipelines

## e2e:package-and-test child pipeline

The `e2e:package-and-test` child pipeline is the main executor of E2E testing for the GitLab platform. The pipeline definition has several dynamic
components to reduce the number of tests being executed in merge request pipelines.

### Setup

Pipeline setup consists of:

- The `e2e-test-pipeline-generate` job in the `prepare` stage of the main GitLab pipeline.
- The `e2e:package-and-test` job in the `qa` stage, which triggers the child pipeline that is responsible for building the `omnibus` package and
  running E2E tests.

#### e2e-test-pipeline-generate

This job consists of two components that implement selective test execution:

- The [`detect_changes`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/qa/tasks/ci.rake) Rake task determines which e2e specs should be executed
  in a particular merge request pipeline. This task analyzes changes in a particular merge request and determines which specs must be executed.
  Based on that, a `dry-run` of every [scenario](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/qa/scenario/test) executes and determines if a
  scenario contains any executable tests. Selective test execution uses [these criteria](index.md#selective-test-execution) to determine which specific
  tests to execute.
- [`generate-e2e-pipeline`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/scripts/generate-e2e-pipeline) is executed, which generates a child
  pipeline YAML definition file with appropriate environment variables.

#### e2e:package-and-test execution pipeline

E2E test execution pipeline consists of several stages which all support execution of E2E tests.

##### .pre

This stage is responsible for the following tasks:

- Fetching `knapsack` reports that support [parallel test execution](index.md#run-tests-in-parallel).
- Triggering downstream pipeline which builds the [`omnibus-gitlab`](https://gitlab.com/gitlab-org/omnibus-gitlab) Docker image.

##### test

This stage runs e2e tests against different types of GitLab configurations. The number of jobs executed is determined dynamically by
[`e2e-test-pipeline-generate`](test_pipelines.md#e2e-test-pipeline-generate) job.

##### report

This stage is responsible for [allure test report](index.md#allure-report) generation.

### Adding new jobs

Selective test execution depends on a set of rules present in every job definition. A typical job contains the following attributes:

```yaml
variables:
  QA_SCENARIO: Test::Integration::MyNewJob
rules:
  - !reference [.rules:test:qa, rules]
  - if: $QA_SUITES =~ /Test::Integration::MyNewJob/
  - !reference [.rules:test:manual, rules]
```

In this example:

- `QA_SCENARIO: Test::Integration::MyNewJob`: name of the scenario class that is passed to the
  [`gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa/-/blob/master/docs/what_tests_can_be_run.md) executor.
- `!reference [.rules:test:qa, rules]`: main rule definition that is matched for pipelines that should execute all tests. For example, when changes to
  `qa` framework are present.
- `if: $QA_SUITES =~ /Test::Integration::MyNewJob/`: main rule responsible for selective test execution. `QA_SUITE` is the name of the scenario
  abstraction located in [`qa framework`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/qa/scenario/test).

  `QA_SUITE` is not the same as `QA_SCENARIO`, which is passed to the `gitlab-qa` executor. For consistency, it usually has the same name. `QA_SUITE`
  abstraction class usually contains information on what tags to run and optionally some additional setup steps.
- `!reference [.rules:test:manual, rules]`: final rule that is always matched and sets the job to `manual` so it can still be executed on demand,
  even if not set to execute by selective test execution.

Considering example above, perform the following steps to create a new job:

1. Create new scenario type `my_new_job.rb` in the [`integration`](https://gitlab.com/gitlab-org/gitlab-qa/-/tree/master/lib/gitlab/qa/scenario/test/integration) directory
   of the [`gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa) project and release new version so it's generally available.
1. Create new scenario `my_new_job.rb` in [`integration`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/qa/scenario/test/integration) directory of the
   [`qa`](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa) framework. In the most simple case, this scenario would define RSpec tags that should be executed:

   ```ruby
   module QA
     module Scenario
       module Test
         module Integration
           class MyNewJob < Test::Instance::All
             tags :some_special_tag
           end
         end
       end
     end
   end
   ```

1. Add new job definition in the [`main.gitlab-ci.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/ci/package-and-test/main.gitlab-ci.yml) pipeline definition:

   ```yaml
   ee:my-new-job:
     extends: .qa
     variables:
       QA_SCENARIO: Test::Integration::MyNewJob
     rules:
       - !reference [.rules:test:qa, rules]
       - if: $QA_SUITES =~ /Test::Integration::MyNewJob/
       - !reference [.rules:test:manual, rules]
   ```

#### Parallel jobs

For selective execution to work correctly with job types that require running multiple parallel jobs,
a job definition typically must be split into parallel and selective variants. Splitting is necessary so that when selective execution
executes only a single spec, multiple unnecessary jobs are not spawned. For example:

```yaml
ee:my-new-job-selective:
  extends: .qa
  variables:
    QA_SCENARIO: Test::Integration::MyNewJob
  rules:
    - !reference [.rules:test:qa-selective, rules]
    - if: $QA_SUITES =~ /Test::Integration::MyNewJob/
ee:my-new-job:
  extends:
    - .parallel
    - ee:my-new-job-selective
  rules:
    - !reference [.rules:test:qa-parallel, rules]
    - if: $QA_SUITES =~ /Test::Integration::MyNewJob/
```

## `e2e:test-on-gdk`

The `e2e:test-on-gdk` child pipeline supports development of the GitLab platform by providing feedback to engineers on
end-to-end test execution faster than via `e2e:package-and-test` or [Review Apps](../review_apps.md).

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
  in the `prepare` stage. This is the same job as in the `e2e:package-and-test` pipeline.
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

#### `e2e:test-on-gdk` child pipeline

Like the `e2e:package-and-test` pipeline, the `e2e:test-on-gdk` pipeline consists of several stages that support
execution of E2E tests.

##### .pre

This stage is responsible for fetching `knapsack` reports that support [parallel test execution](index.md#run-tests-in-parallel).

##### test

This stage runs e2e tests against different types of GitLab configurations. The number of jobs executed is determined dynamically by the
[`e2e-test-pipeline-generate`](test_pipelines.md#e2e-test-pipeline-generate) job.

Each job starts a container from the GDK Docker image created in the `build-gdk-image` job, and then executes the end-to-end
tests against the GDK instance running in the container.

##### report

This stage is responsible for [allure test report](index.md#allure-report) generation.

## `e2e:test-on-cng`

The `e2e:test-on-cng` child pipeline runs tests against [Cloud Native GitLab](https://gitlab.com/gitlab-org/build/CNG) installation.
Unlike `review-apps`, this pipeline uses local [kind](https://github.com/kubernetes-sigs/kind) Kubernetes cluster.

Currently this pipeline is executed on nightly scheduled pipelines and is mainly responsible for testing compatibility with minimal supported version of `redis`.

### Setup

The pipeline setup consists of several jobs in the main GitLab pipeline:

- `compile-production-assets` and `build-assets-image` jobs are responsible for compiling frontend assets which are required
by [CNG](https://gitlab.com/gitlab-org/build/CNG-mirror) build pipeline.
- `e2e-test-pipeline-generate` job is responsible for generating `e2e:test-on-cng` child pipeline

### `e2e:test-on-cng` child pipeline

Child pipeline consists of several stages that support E2E test execution.

#### .pre

- `build-cng-env` job is responsible for setting up all environment variables for [CNG](https://gitlab.com/gitlab-org/build/CNG-mirror) downstream pipeline
- `build-cng` job triggers `CNG` downstream pipeline which is responsible for building all necessary images

#### test

Jobs in `test` stage perform following actions:

- local k8s cluster setup using [`kind`](https://github.com/kubernetes-sigs/kind)
- GitLab installation using official [`helm` chart](https://gitlab.com/gitlab-org/charts/gitlab)
- E2E test execution against performed deployment

#### report

This stage is responsible for [allure test report](index.md#allure-report) generation as well as test metrics upload.
