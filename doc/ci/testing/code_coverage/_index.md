---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Track coverage percentages and visualize line-by-line test coverage in merge requests.
title: Code coverage
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

To track code coverage in merge requests, you can display a percentage in the MR widget,
annotate individual lines in the MR diff, or both. Each output requires a separate keyword.
Configuring one does not enable the other.

| Output                                                                           | Keyword |
| -------------------------------------------------------------------------------- | ------- |
| Show a coverage percentage in the MR widget, pipeline list, and analytics graphs | [`coverage`](../../yaml/_index.md#coverage) |
| Show line-by-line annotations in the MR diff                                     | [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report) |

To get both outputs, configure both keywords.

## Coverage reporting

Coverage reporting extracts a percentage from your test tool's job log output.
You define a regular expression in the `coverage` keyword. GitLab scans the job log,
extracts the first matching number, and stores it.

GitLab displays this value in:

- The MR widget, including the delta compared to the target branch.
- The pipeline job list.
- Per-project and per-group coverage history graphs in **Analyze** > **Repository analytics**.
- Coverage badges.
- The `Coverage-Check` approval rule (Premium and Ultimate), which can require approval
  when coverage drops.

For setup instructions, see [configure coverage reporting](coverage_reporting.md).

## Coverage visualization

Coverage visualization parses a Cobertura or JaCoCo XML report that your test job uploads
as a CI/CD artifact. After the pipeline completes, GitLab processes the report in the
background and annotates lines in the MR diff.

Annotations appear only on files that are changed in the MR diff. Files not changed in
the MR are not annotated, even if the report includes coverage data for them.

For setup instructions, see [configure coverage visualization](coverage_visualization.md).
