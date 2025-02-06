---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Test coverage visualization
---

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

With the help of [GitLab CI/CD](../../index.md), you can collect the test
coverage information of your favorite testing or coverage-analysis tool, and visualize
this information inside the file diff view of your merge requests (MRs). This allows you
to see which lines are covered by tests, and which lines still require coverage, before the
MR is merged.

![Test Coverage Visualization Diff View](../img/test_coverage_visualization_v12_9.png)

GitLab supports two coverage report formats:

- [Cobertura](cobertura.md)
- [JaCoCo](jacoco.md)

## How test coverage visualization works

Collecting the coverage information is done by using the GitLab CI/CD
[artifacts reports feature](../../yaml/_index.md#artifactsreports).
You can specify one or more coverage reports to collect, including wildcard paths.
GitLab then takes the coverage information in all the files and combines it
together. Coverage files are parsed in a background job so there can be a delay
between pipeline completion and the visualization loading on the page.

## Data expiration

By default, the data used to draw the visualization on the merge request expires **one week** after creation.

## Coverage report from child pipeline

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/363301) in GitLab 15.1 [with a flag](../../../administration/feature_flags.md) named `ci_child_pipeline_coverage_reports`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/363557) and feature flag `ci_child_pipeline_coverage_reports` removed in GitLab 15.2.

If a job in a child pipeline creates a coverage report, the report is included in
the parent pipeline's coverage report.

```yaml
child_test_pipeline:
  trigger:
    include:
      - local: path/to/child_pipeline_with_coverage.yml
```
