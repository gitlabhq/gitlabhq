---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see <https://docs.gitlab.com/development/development_processes/#development-guidelines-review>.
title: Test results tracking
---

## Rails test results tracking

`GitlabQuality::TestTooling::TestMetricsExporter::Formatter` from the
[`gitlab_quality-test_tooling`](https://gitlab.com/gitlab-org/ruby/gems/gitlab_quality-test_tooling)
gem exports test execution data to a ClickHouse instance
during CI pipeline runs, collecting per-example metrics including run type,
pipeline type, feature category, and ownership information.

Use the [test metrics dashboards](https://dashboards.gitlab.net/dashboards/f/dx/dx?tag=test-metrics)
to view test results, track flaky tests, and monitor test suite health.

Additionally, see [flaky tests](https://handbook.gitlab.com/handbook/engineering/testing/flaky-tests/) handbook page on how
this data is used for flaky test reporting.

## End-to-end test results tracking

This is described specifically in [Test results tracking](https://handbook.gitlab.com/handbook/engineering/quality/#test-results-tracking/).

For the E2E test suite, we use the following commands from the gem (see the gem's README for details about each command):

- `prepare-stage-reports`
- `generate-test-session`
- `report-results`
- `update-screenshot-paths`
- `relate-failure-issue`
