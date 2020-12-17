---
stage: Verify
group: Testing
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# Metrics Reports **(PREMIUM)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/9788) in [GitLab Premium](https://about.gitlab.com/pricing/) 11.10. Requires GitLab Runner 11.10 and above.

GitLab provides a lot of great reporting tools for [merge requests](../user/project/merge_requests/index.md) - [Unit test reports](unit_test_reports.md), [code quality](../user/project/merge_requests/code_quality.md), performance tests, etc. While JUnit is a great open framework for tests that "pass" or "fail", it is also important to see other types of metrics from a given change.

You can configure your job to use custom Metrics Reports, and GitLab displays a report on the merge request so that it's easier and faster to identify changes without having to check the entire log.

![Metrics Reports](img/metrics_reports_v13_0.png)

## Use cases

Consider the following examples of data that can use Metrics Reports:

1. Memory usage
1. Load testing results
1. Code complexity
1. Code coverage stats

## How it works

Metrics are read from the metrics report (default: `metrics.txt`). They are parsed and displayed in the MR widget.

All values are considered strings and string compare is used to find differences between the latest available `metrics` artifact from:

- `master`
- The feature branch

## How to set it up

Add a job that creates a [metrics report](pipelines/job_artifacts.md#artifactsreportsmetrics) (default filename: `metrics.txt`). The file should conform to the [OpenMetrics](https://openmetrics.io/) format.

For example:

```yaml
metrics:
  script:
    - echo 'metric_name metric_value' > metrics.txt
  artifacts:
    reports:
      metrics: metrics.txt
```

## Advanced Example

An advanced example of an OpenMetrics text file (from the [Prometheus documentation](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-format-example))
renders in the merge request widget as:

![Metrics Reports Advanced](img/metrics_reports_advanced_v13_0.png)
