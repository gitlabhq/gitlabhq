---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# End-to-end Testing

## What is end-to-end testing?

End-to-end testing is a strategy used to check whether your application works
as expected across the entire software stack and architecture, including
integration of all micro-services and components that are supposed to work
together.

## How do we test GitLab?

We use [Omnibus GitLab](https://gitlab.com/gitlab-org/omnibus-gitlab) to build GitLab packages and then we
test these packages using the [GitLab QA orchestrator](https://gitlab.com/gitlab-org/gitlab-qa) tool, which is
a black-box testing framework for the API and the UI.

### Testing nightly builds

We run scheduled pipelines each night to test nightly builds created by Omnibus.
You can find these pipelines at <https://gitlab.com/gitlab-org/quality/nightly/pipelines>
(requires the Developer role). Results are reported in the `#qa-nightly` Slack channel.

### Testing staging

We run scheduled pipelines each night to test staging.
You can find these pipelines at <https://gitlab.com/gitlab-org/quality/staging/pipelines>
(requires the Developer role). Results are reported in the `#qa-staging` Slack channel.

### Testing code in merge requests

#### Using the `package-and-qa` job

It is possible to run end-to-end tests for a merge request, eventually being run in
a pipeline in the [`gitlab-org/gitlab-qa-mirror`](https://gitlab.com/gitlab-org/gitlab-qa-mirror) project,
by triggering the `package-and-qa` manual action in the `qa` stage (not
available for forks).

**This runs end-to-end tests against a custom EE (with an Ultimate license)
Docker image built from your merge request's changes.**

Manual action that starts end-to-end tests is also available
in [`gitlab-org/omnibus-gitlab` merge requests](https://docs.gitlab.com/omnibus/build/team_member_docs.html#i-have-an-mr-in-the-omnibus-gitlab-project-and-want-a-package-or-docker-image-to-test-it).

#### How does it work?

Currently, we are using _multi-project pipeline_-like approach to run end-to-end
pipelines.

```mermaid
graph TB
    A1 -.->|once done, can be triggered| A2
    A2 -.->|1. Triggers an `omnibus-gitlab-mirror` pipeline<br>and wait for it to be done| B1
    B2[`Trigger-qa` stage<br>`Trigger:qa-test` job] -.->|2. Triggers a `gitlab-qa-mirror` pipeline<br>and wait for it to be done| C1

subgraph "`gitlab-org/gitlab` pipeline"
    A1[`build-images` stage<br>`build-qa-image` and `build-assets-image` jobs]
    A2[`qa` stage<br>`package-and-qa` job]
    end

subgraph "`gitlab-org/build/omnibus-gitlab-mirror` pipeline"
    B1[`Trigger-docker` stage<br>`Trigger:gitlab-docker` job] -->|once done| B2
    end

subgraph "`gitlab-org/gitlab-qa-mirror` pipeline"
    C1>End-to-end jobs run]
    end
```

1. In the [`gitlab-org/gitlab` pipeline](https://gitlab.com/gitlab-org/gitlab):
   1. Developer triggers the `package-and-qa` manual action (available once the `build-qa-image` and
      `build-assets-image` jobs are done), that can be found in GitLab merge
      requests. This starts a chain of pipelines in multiple projects.
   1. The script being executed triggers a pipeline in
      [`gitlab-org/build/omnibus-gitlab-mirror`](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror)
      and polls for the resulting status. We call this a _status attribution_.

1. In the [`gitlab-org/build/omnibus-gitlab-mirror` pipeline](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror):
   1. Docker image is being built and pushed to its Container Registry.
   1. Finally, the `Trigger:qa-test` job triggers a new end-to-end pipeline in
      [`gitlab-org/gitlab-qa-mirror`](https://gitlab.com/gitlab-org/gitlab-qa-mirror/pipelines) and polls for the resulting status.

1. In the [`gitlab-org/gitlab-qa-mirror` pipeline](https://gitlab.com/gitlab-org/gitlab-qa-mirror):
   1. Container for the Docker image stored in the [`gitlab-org/build/omnibus-gitlab-mirror`](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror) registry is spun-up.
   1. End-to-end tests are run with the `gitlab-qa` executable, which spin up a container for the end-to-end image from the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) registry.

1. The result of the [`gitlab-org/gitlab-qa-mirror` pipeline](https://gitlab.com/gitlab-org/gitlab-qa-mirror) is being
   propagated upstream (through polling from upstream pipelines), through [`gitlab-org/build/omnibus-gitlab-mirror`](https://gitlab.com/gitlab-org/build/omnibus-gitlab-mirror), back to the [`gitlab-org/gitlab`](https://gitlab.com/gitlab-org/gitlab) merge request.

Please note, we plan to [add more specific information](https://gitlab.com/gitlab-org/quality/team-tasks/-/issues/156)
about the tests included in each job/scenario that runs in `gitlab-org/gitlab-qa-mirror`.

NOTE:
You may have noticed that we use `gitlab-org/build/omnibus-gitlab-mirror` instead of
`gitlab-org/omnibus-gitlab`, and `gitlab-org/gitlab-qa-mirror` instead of `gitlab-org/gitlab-qa`.
This is due to technical limitations in the GitLab permission model: the ability to run a pipeline
against a protected branch is controlled by the ability to push/merge to this branch.
This means that for developers to be able to trigger a pipeline for the default branch in
`gitlab-org/omnibus-gitlab`/`gitlab-org/gitlab-qa`, they would need to have the
[Maintainer role](../../../user/permissions.md) for those projects.
For security reasons and implications, we couldn't open up the default branch to all the Developers.
Hence we created these mirrors where Developers and Maintainers are allowed to push/merge to the default branch.
This problem was discovered in <https://gitlab.com/gitlab-org/gitlab-qa/-/issues/63#note_107175160> and the "mirror"
work-around was suggested in <https://gitlab.com/gitlab-org/omnibus-gitlab/-/issues/4717>.
A feature proposal to segregate access control regarding running pipelines from ability to push/merge was also created at <https://gitlab.com/gitlab-org/gitlab/-/issues/24585>.

#### With Pipeline for Merged Results

In a Pipeline for Merged Results, the pipeline runs on a new ref that contains the merge result of the source and target branch.
However, this ref is not available to the `gitlab-qa-mirror` pipeline.

For this reason, the end-to-end tests on a Pipeline for Merged Results would use the head of the merge request source branch.

```mermaid
graph LR

A["a1b1c1 - branch HEAD (CI_MERGE_REQUEST_SOURCE_BRANCH_SHA)"]
B["x1y1z1 - master HEAD"]
C["d1e1f1 - merged results (CI_COMMIT_SHA)"]

A --> C
B --> C

A --> E["E2E tests"]
C --> D["Pipeline for merged results"]
 ```

##### Running custom tests

The [existing scenarios](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md)
that run in the downstream `gitlab-qa-mirror` pipeline include many tests, but there are times when you might want to run a
test or a group of tests that are different than the groups in any of the existing scenarios.

For example, when we [dequarantine](https://about.gitlab.com/handbook/engineering/quality/guidelines/debugging-qa-test-failures/#dequarantining-tests)
a flaky test we first want to make sure that it's no longer flaky.
We can do that using the `ce:custom-parallel` and `ee:custom-parallel` jobs.
Both are manual jobs that you can configure using custom variables.
When clicking the name (not the play icon) of one of the parallel jobs,
you are prompted to enter variables. You can use any of [the variables
that can be used with `gitlab-qa`](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md#supported-gitlab-environment-variables)
as well as these:

| Variable | Description |
|-|-|
| `QA_SCENARIO` | The scenario to run (default `Test::Instance::Image`) |
| `QA_TESTS` | The test(s) to run (no default, which means run all the tests in the scenario). Use file paths as you would when running tests via RSpec, e.g., `qa/specs/features/ee/browser_ui` would include all the `EE` UI tests. |
| `QA_RSPEC_TAGS` | The RSpec tags to add (no default) |

For now [manual jobs with custom variables don't use the same variable
when retried](https://gitlab.com/gitlab-org/gitlab/-/issues/31367), so if you want to run the same test(s) multiple times,
specify the same variables in each `custom-parallel` job (up to as
many of the 10 available jobs that you want to run).

#### Using the `review-qa-all` jobs

On every pipeline during the `test` stage, the `review-qa-smoke` job is
automatically started: it runs the QA smoke suite against the
[Review App](../review_apps.md).

You can also manually start the `review-qa-all`: it runs the full QA suite
against the [Review App](../review_apps.md).

**This runs end-to-end tests against a Review App based on [the official GitLab
Helm chart](https://gitlab.com/gitlab-org/charts/gitlab/), itself deployed with custom
[Cloud Native components](https://gitlab.com/gitlab-org/build/CNG) built from your merge request's changes.**

See [Review Apps](../review_apps.md) for more details about Review Apps.

## How do I run the tests?

If you are not [testing code in a merge request](#testing-code-in-merge-requests),
there are two main options for running the tests. If you want to run
the existing tests against a live GitLab instance or against a pre-built Docker image,
use the [GitLab QA orchestrator](https://gitlab.com/gitlab-org/gitlab-qa/tree/master/README.md). See also [examples
of the test scenarios you can run via the orchestrator](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/what_tests_can_be_run.md#examples).

On the other hand, if you would like to run against a local development GitLab
environment, you can use the [GitLab Development Kit (GDK)](https://gitlab.com/gitlab-org/gitlab-development-kit/).
Please refer to the instructions in the [QA README](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/README.md#how-can-i-use-it)
and the section below.

### Running tests that require special setup

Learn how to perform [tests that require special setup or consideration to run on your local environment](running_tests_that_require_special_setup.md).

## How do I write tests?

In order to write new tests, you first need to learn more about GitLab QA
architecture. See the [documentation about it](https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/architecture.md).

Once you decided where to put [test environment orchestration scenarios](https://gitlab.com/gitlab-org/gitlab-qa/tree/master/lib/gitlab/qa/scenario) and
[instance-level scenarios](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/qa/qa/specs/features), take a look at the [GitLab QA README](https://gitlab.com/gitlab-org/gitlab/-/tree/master/qa/README.md),
the [GitLab QA orchestrator README](https://gitlab.com/gitlab-org/gitlab-qa/tree/master/README.md), and [the already existing
instance-level scenarios](https://gitlab.com/gitlab-org/gitlab-foss/tree/master/qa/qa/specs/features).

### Consider **not** writing an end-to-end test

We should follow these best practices for end-to-end tests:

- Do not write an end-to-end test if a lower-level feature test exists. End-to-end tests require more work and resources.
- Troubleshooting for end-to-end tests can be more complex as connections to the application under test are not known.

Continued reading:

- [Beginner's Guide](beginners_guide.md)
- [Style Guide](style_guide.md)
- [Best Practices](best_practices.md)
- [Testing with feature flags](feature_flags.md)
- [Flows](flows.md)
- [RSpec metadata/tags](rspec_metadata_tests.md)
- [Execution context selection](execution_context_selection.md)

## Where can I ask for help?

You can ask question in the `#quality` channel on Slack (GitLab internal) or
you can find an issue you would like to work on in
[the `gitlab` issue tracker](https://gitlab.com/gitlab-org/gitlab/-/issues?label_name%5B%5D=QA&label_name%5B%5D=test), or
[the `gitlab-qa` issue tracker](https://gitlab.com/gitlab-org/gitlab-qa/-/issues?label_name%5B%5D=new+scenario).
