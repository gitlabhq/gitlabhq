---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Run only the RSpec specs relevant to your merge request changes to get pipeline feedback faster.
title: Fail fast testing
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Fail fast testing runs the test specs most relevant to your merge request changes
before the rest of the suite runs. If those specs fail,
the pipeline stops immediately to save time and compute resources.

For Ruby on Rails projects that use RSpec, the
[`Verify/FailFast` CI/CD template](https://gitlab.com/gitlab-org/gitlab/-/tree/master/lib/gitlab/ci/templates/Verify/FailFast.gitlab-ci.yml)
selects and runs only the relevant specs. It uses the
[`test_file_finder` (`tff`) gem](https://gitlab.com/gitlab-org/ruby/gems/test_file_finder),
which maps changed files to their related spec files.

By default, the template runs in the [`.pre` stage](../yaml/_index.md#stage-pre),
before all other pipeline stages.

## Configure fail fast testing

Configure fail fast testing to get faster feedback on merge request changes
before your full test suite runs.

Prerequisites:

- A Ruby on Rails project that uses RSpec.
- [Merged results pipelines](../pipelines/merged_results_pipelines.md#enable-merged-results-pipelines)
  enabled in the project settings. This also requires
  [merge request pipelines](../pipelines/merge_request_pipelines.md#prerequisites) to be enabled.

To configure fail fast testing:

1. Add an RSpec job to run your full suite on merge request pipelines:

   ```yaml
   rspec-complete:
     stage: test
     rules:
       - if: $CI_PIPELINE_SOURCE == "merge_request_event"
     script:
       - bundle install
       - bundle exec rspec
   ```

1. Include the `Verify/FailFast` template in your CI/CD configuration:

   ```yaml
   include:
     - template: Verify/FailFast.gitlab-ci.yml
   ```

1. Optional. To use a different Docker image, set the image on the
   `rspec-rails-modified-path-specs` job in your CI/CD configuration file:

   ```yaml
   include:
     - template: Verify/FailFast.gitlab-ci.yml

   rspec-rails-modified-path-specs:
     image: custom-docker-image-with-ruby
   ```

## Fail fast test results

The following examples assume a suite of 100 specs per model across 10 models (1000 specs total).

| Changed files                            | `rspec-rails-modified-path-specs` | `rspec-complete` |
| ---------------------------------------- | --------------------------------- | ---------------- |
| No Ruby files                            | Does not run                      | Runs all 1000 specs |
| `app/models/example.rb` (all specs pass) | Runs 100 specs for `example.rb`   | Runs all 1000 specs |
| `app/models/example.rb` (any spec fails) | Runs 100 specs for `example.rb`   | Skipped          |
