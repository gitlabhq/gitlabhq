---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Fail Fast Testing
---

DETAILS:
**Tier:** Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

For applications that use RSpec for running tests, we've introduced the `Verify/Failfast`
[template to run subsets of your test suite](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Verify/FailFast.gitlab-ci.yml),
based on the changes in your merge request.

The template uses the [`test_file_finder` (`tff`) gem](https://gitlab.com/gitlab-org/ruby/gems/test_file_finder)
that accepts a list of files as input, and returns a list of spec (test) files
that it believes to be relevant to the input files.

`tff` is designed for Ruby on Rails projects, so the `Verify/FailFast` template is
configured to run when changes to Ruby files are detected. By default, it runs in
the [`.pre` stage](../yaml/_index.md#stage-pre) of a GitLab CI/CD pipeline,
before all other stages.

## Example use case

Fail fast testing is useful when adding new functionality to a project and adding
new automated tests.

Your project could have hundreds of thousands of tests that take a long time to complete.
You may expect a new test to pass, but you have to wait for all the tests
to complete to verify it. This could take an hour or more, even when using parallelization.

Fail fast testing gives you a faster feedback loop from the pipeline. It lets you
know quickly that the new tests are passing and the new functionality did not break
other tests.

## Prerequisites

This template requires:

- A project built in Rails that uses RSpec for testing.
- CI/CD configured to:
  - Use a Docker image with Ruby available.
  - Use [Merge request pipelines](../pipelines/merge_request_pipelines.md#prerequisites)
- [Merged results pipelines](../pipelines/merged_results_pipelines.md#enable-merged-results-pipelines)
  enabled in the project settings.
- A Docker image with Ruby available. The template uses `image: ruby:2.6` by default, but you [can override](../yaml/includes.md#override-included-configuration-values) this.

## Configuring Fast RSpec Failure

We use the following plain RSpec configuration as a starting point. It installs all the
project gems and executes `rspec`, on merge request pipelines only.

```yaml
rspec-complete:
  stage: test
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
  script:
    - bundle install
    - bundle exec rspec
```

To run the most relevant specs first instead of the whole suite, [`include`](../yaml/_index.md#include)
the template by adding the following to your CI/CD configuration:

```yaml
include:
  - template: Verify/FailFast.gitlab-ci.yml
```

To customize the job, specific options may be set to override the template. For example, to override the default Docker image:

```yaml
include:
  - template: Verify/FailFast.gitlab-ci.yml

rspec-rails-modified-path-specs:
  image: custom-docker-image-with-ruby
```

### Example test loads

For illustrative purposes, let's say our Rails app spec suite consists of 100 specs per model for ten models.

If no Ruby files are changed:

- `rspec-rails-modified-paths-specs` does not run any tests.
- `rspec-complete` runs the full suite of 1000 tests.

If one Ruby model is changed, for example `app/models/example.rb`, then `rspec-rails-modified-paths-specs`
runs the 100 tests for `example.rb`:

- If all of these 100 tests pass, then the full `rspec-complete` suite of 1000 tests is allowed to run.
- If any of these 100 tests fail, they fail quickly, and `rspec-complete` does not run any tests.

The final case saves resources and time as the full 1000 test suite does not run.
