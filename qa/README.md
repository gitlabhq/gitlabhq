# GitLab QA - End-to-end tests for GitLab

This directory contains [end-to-end tests](../doc/development/testing_guide/end_to_end/index.md)
for GitLab. It includes the test framework and the tests themselves.

The tests can be found in `qa/specs/features` (not to be confused with the unit
tests for the test framework, which are in `spec/`).

Tests use [GitLab QA project](https://gitlab.com/gitlab-org/gitlab-qa) for environment orchestration in CI jobs.

## What is it?

GitLab QA is an end-to-end test framework designed for test GitLab.

These are black-box and entirely click-driven end-to-end tests you can run against any existing instance of GitLab.

## How does it work?

1. When we release a new version of GitLab, we build a Docker images for it.
1. Along with GitLab Docker Images we also build and publish GitLab QA images.
1. QA image can be used to execute e2e tests against running instance of GitLab.

## Validating GitLab views / partials / selectors in merge requests

We recently added a new CI job that is going to be triggered for every push
event in CE and EE projects. The job is called `qa:selectors` and it will
verify coupling between page objects implemented as a part of GitLab QA
and corresponding views / partials / selectors in CE / EE.

Whenever `qa:selectors` job fails in your merge request, you are supposed to
fix [page objects](../doc/development/testing_guide/end_to_end/page_objects.md). You should also trigger end-to-end tests
using `package-and-qa` manual action, to test if everything works fine.

## How can I use it?

You can use GitLab QA to exercise tests on any live instance! If you don't
have an instance available you can follow the instructions below to use
the [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit).
This is the recommended option if you would like to contribute to the tests.

Note that tests are using `Chrome` web browser by default so it should be installed and present in `PATH`.

## CI

Tests are executed in merge request pipelines as part of the development lifecycle. CI pipeline setup and different types of environments are described in [test pipelines](../doc/development/testing_guide/end_to_end/test_pipelines.md) documentation page.

### Including tests in other projects

Pipeline template for `test-on-omnibus` E2E tests is designed in a way so it can be included as a child pipeline in other projects.

Minimal configuration example would look like this:

```yaml
qa-test:
  stage: test
  variables:
    RELEASE: EE
  trigger:
    strategy: depend
    forward:
      yaml_variables: true
      pipeline_variables: true
    include:
      - project: gitlab-org/gitlab
        ref: master
        file: .gitlab/ci/test-on-omnibus/main.gitlab-ci.yml
```

To set GitLab version used for testing, following environment variables can be used:

- `RELEASE`: `omnibus` release, can be string value `EE` or `CE` for nightly release of enterprise or community edition of GitLab or can be fully qualified Docker image name
- `QA_IMAGE`: Docker image of qa code. By default inferred from `RELEASE` but can be explicitly overridden with this variable

#### Test specific environment variables

Special GitLab configurations require various specific environment variables to be present for tests to work. These can be provisioned automatically using `terraform` setup in [engineering-productivity-infrastructure](https://gitlab.com/gitlab-org/quality/engineering-productivity-infrastructure/-/tree/main/qa-resources/modules/e2e-ci) project.

### Logging

By default tests on CI use `info` log level. `debug` level is still available in case of failure debugging. Logs are stored in jobs artifacts.

### Writing tests

- [Writing tests from scratch tutorial](../doc/development/testing_guide/end_to_end/beginners_guide.md)
  - [Best practices](../doc/development/testing_guide/best_practices.md)
  - [Using page objects](../doc/development/testing_guide/end_to_end/page_objects.md)
  - [Guidelines](../doc/development/testing_guide/index.md)
  - [Tests with special setup for local environments](../doc/development/testing_guide/end_to_end/running_tests_that_require_special_setup.md)

### Running tests

- [Against your GDK environment](../doc/development/testing_guide/end_to_end/running_tests/index.md#against-your-gdk-environment)
- [Against GitLab in Docker](../doc/development/testing_guide/end_to_end/running_tests/index.md#against-gitlab-in-docker)
- [Specific types of tests](../doc/development/testing_guide/end_to_end/running_tests/index.md#specific-types-of-tests)
- [Test configuration](../doc/development/testing_guide/end_to_end/running_tests/index.md#test-configuration)

### Building a Docker image to test

Once you have made changes to the CE/EE repositories, you may want to build a
Docker image to test locally instead of waiting for the `gitlab-ce-qa` or
`gitlab-ee-qa` nightly builds. To do that, you can run **from the top `gitlab`
directory** (one level up from this directory):

```sh
docker build -t gitlab/gitlab-ce-qa:nightly --file ./qa/Dockerfile ./
```
