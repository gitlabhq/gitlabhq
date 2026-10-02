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

Use coverage reporting and coverage visualization to track code coverage. The two mechanisms
read different inputs, produce different outputs, and don't share configuration.
Configuring one does not enable the other.

Coverage reporting shows a percentage in the MR widget, the pipeline list, and analytics graphs.
Coverage visualization shows line-by-line annotations in the MR diff. To get both, configure both
keywords ([`coverage`](../../yaml/_index.md#coverage) and
[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)).

## Where coverage appears

Use this table to find the keyword for the coverage output you want. The `coverage` keyword
powers every output except diff annotations.

| Surface                                                 | Where to find it                             | Keyword                             | Tier |
| ------------------------------------------------------- | -------------------------------------------- | ----------------------------------- | ---- |
| Coverage percentage and delta against the target branch | MR widget                                    | `coverage`                          | Free |
| Line-by-line annotations                                | MR diff, changed files only                  | `artifacts:reports:coverage_report` | Free |
| Per-job coverage percentage                             | Pipeline and job lists                       | `coverage`                          | Free |
| Coverage badge                                          | Anywhere you embed the badge URL             | `coverage`                          | Free |
| Coverage history and CSV export                         | **Analyze > Repository analytics** (project) | `coverage`                          | Free |
| Group coverage history and CSV export                   | **Analyze > Repository analytics** (group)   | `coverage`                          | Premium and Ultimate |
| `Coverage-Check` approval rule                          | **Settings > Merge requests**                | `coverage`                          | Premium and Ultimate |

## Choose an approach

The two mechanisms read different inputs and behave differently.

|                 | Coverage reporting                               | Coverage visualization                    |
|-----------------|--------------------------------------------------|-------------------------------------------|
| Keyword         | `coverage`                                       | `artifacts:reports:coverage_report`       |
| Input           | A regular expression matched against the job log | A Cobertura or JaCoCo XML artifact        |
| Produces        | A single number per job                          | Per-line annotations on changed files     |
| Available       | When the job completes                           | After the whole pipeline completes        |
| Child pipelines | Not recorded                                     | Recorded                                  |
| Fails by        | Showing no percentage                            | Silently skipping annotations             |

Because the two mechanisms read different inputs, they can disagree.
The percentage in the MR widget is whatever your regex matched in the log.
The annotations come from the XML report. If your test command computes these on different bases,
the widget and the diff describe different things. Generate both from the same test run.

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
