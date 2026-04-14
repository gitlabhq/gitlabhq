---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Track and compare performance, memory, and custom metrics.
title: Metrics reports
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Metrics reports display custom metrics in merge requests to track performance,
memory usage, and other measurements between branches.

Use metrics reports to:

- Monitor memory usage changes.
- Track load testing results.
- Measure code complexity.
- Compare code coverage statistics.

## Metrics processing workflow

When a pipeline runs, GitLab reads metrics from the report artifact and stores them as string values
for comparison. The default filename is `metrics.txt`.

For a merge request, GitLab compares the metrics from the feature branch to the values from the target
branch and displays them in the merge request widget in this order:

- Existing metrics with changed values.
- Metrics added by the merge request (marked with a **New** badge).
- Metrics removed by the merge request (marked with a **Removed** badge).
- Existing metrics with unchanged values.

### Baseline pipeline selection

To compare metrics between branches, GitLab identifies a baseline pipeline on the target branch using this process:

1. Checks for a pipeline on the target branch that matches these commit SHAs, in order:
   1. The target branch tip at the time the
      [merge request pipeline](../pipelines/merge_request_pipelines.md)
      was created.
      This SHA is only available for merge request pipelines.
   1. The merge-base commit (the common ancestor of the source and target branches).
   1. The start commit of the merge request diff.
1. Selects the most recently created pipeline (by pipeline ID) for the first SHA
   that has a matching pipeline.

The baseline pipeline selection:

- Does not filter by pipeline status.
  A pipeline in any state (`success`, `failed`, `canceled`, or `skipped`)
  can be selected as the baseline.
- Does not check whether the baseline pipeline has metrics report artifacts.
  If the baseline pipeline exists but has no metrics artifacts, all metrics
  from the feature branch are displayed as new.

The metrics comparison widget appears only when the feature branch pipeline is in a
completed state and has metrics report artifacts.

The type of pipeline affects which commit SHA is matched first:

- Merge request pipelines: The target branch tip SHA is usually available,
  so the baseline is typically the latest pipeline at the target branch tip
  when the merge request pipeline was created.
- Branch pipelines: The target branch tip SHA is not available,
  so the merge-base commit is used instead. The baseline is the latest pipeline on
  the target branch at the common ancestor commit.

To ensure a baseline is always available for comparison:

- Run pipelines on your target branch that produce metrics report artifacts.
- If you use branch pipelines,
  ensure the merge-base commit has a pipeline on the target branch.

## Configure metrics reports

Add metrics reports to your CI/CD pipeline to track custom metrics in merge requests.

Prerequisites:

- The metrics file must use the [OpenMetrics](https://prometheus.io/docs/instrumenting/exposition_formats/#openmetrics-text-format) text format.

To configure metrics reports:

1. In your `.gitlab-ci.yml` file, add a job that generates a metrics report.
1. Add a script to the job that generates metrics in OpenMetrics format.
1. Configure the job to upload the metrics file with [`artifacts:reports:metrics`](../yaml/artifacts_reports.md#artifactsreportsmetrics).

For example:

```yaml
metrics:
  stage: test
  script:
    - echo 'memory_usage_bytes 2621440' > metrics.txt
    - echo 'response_time_seconds 0.234' >> metrics.txt
    - echo 'test_coverage_percent 87.5' >> metrics.txt
    - echo '# EOF' >> metrics.txt
  artifacts:
    reports:
      metrics: metrics.txt
```

After the pipeline runs, the metrics reports display in the merge request widget.

![Metrics report widget in a merge request displaying metric names and values.](img/metrics_report_v18_3.png)

For additional format specifications and examples, see
[Prometheus text format details](https://prometheus.io/docs/instrumenting/exposition_formats/#text-format-details).

## Troubleshooting

When working with metrics reports, you might encounter the following issues.

### Metrics reports did not change

You might see **Metrics report scanning detected no new changes** when viewing metrics reports in merge requests.

This issue occurs when:

- The target branch doesn't have a baseline metrics report for comparison.
- Your GitLab subscription doesn't include metrics reports (Premium or Ultimate required).

To resolve this issue:

1. Verify your GitLab subscription tier includes metrics reports.
1. Ensure the target branch has a pipeline with metrics reports configured.
   To ensure one is available, run pipelines on the target branch that produce metrics report artifacts.
1. Verify that your metrics file uses valid OpenMetrics format.
