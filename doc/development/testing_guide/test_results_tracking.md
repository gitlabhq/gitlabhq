---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Test results tracking
---

We developed the [`gitlab_quality-test_tooling`](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling) gem that includes several commands to automate test results tracking.

The goal of this gem is to have a consolidated set of tooling that we use across our various test suite (for example, GitLab Rails & E2E test suites).

The initial motivation and development was tracked by [this epic](https://gitlab.com/groups/gitlab-org/-/epics/10536).

## Rails test results tracking

We [plan to use](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122008) the `relate-failure-issue` command from the gem (see the gem's README for details about the command).

## End-to-end test results tracking

This is described specifically in [Test results tracking](https://handbook.gitlab.com/handbook/engineering/quality/#test-results-tracking/).

For the E2E test suite, we use the following commands from the gem (see the gem's README for details about each command):

- `prepare-stage-reports`
- `generate-test-session`
- `report-results`
- `update-screenshot-paths`
- `relate-failure-issue`
