---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Display line-by-line test coverage annotations in merge request diffs using Cobertura or JaCoCo reports.
title: Coverage visualization
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use the [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)
keyword to display line-by-line coverage annotations in merge request diffs.

This keyword displays diff annotations only. It does not display a coverage percentage in the
MR widget or populate coverage history graphs. To display a coverage percentage, configure
the [`coverage`](../../yaml/_index.md#coverage) keyword separately.

After the pipeline completes, GitLab processes the report in the background and annotates
lines in the MR diff:

- Green: the line is covered by tests.
- Red: the line is not covered by tests.
- Orange (Cobertura only): the line is loaded but never executed.

Annotations appear only on files changed in the MR diff. Files not changed in the MR are
not annotated, even if the report includes coverage data for them.

## Configure coverage visualization

To configure coverage visualization, add `artifacts:reports:coverage_report` to your job:

```yaml
test:
  script:
    - run tests with coverage
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura  # or jacoco
        path: coverage/coverage.xml
```

For language-specific examples, see:

- [Cobertura](cobertura.md)
- [JaCoCo](jacoco.md)

To collect multiple reports, use a
[wildcard in the artifact path](../../jobs/job_artifacts.md#with-wildcards).
GitLab merges the results into a single report.

Coverage reports from child pipelines appear in MR diff annotations.

## Limits

| Limit                                            | Value |
| ------------------------------------------------ | ----- |
| Maximum Cobertura XML file size                  | 10 MiB |
| Maximum `<source>` nodes in a Cobertura XML file | 100   |

If your Cobertura report exceeds 100 `<source>` nodes, annotations may be missing or
mismatched in the diff view. For large projects, split the report into smaller files.
See [issue 328772](https://gitlab.com/gitlab-org/gitlab/-/issues/328772) for details.

The visualization appears only after the pipeline completes. If the pipeline has a
[blocking manual job](../../jobs/job_control.md#types-of-manual-jobs), the visualization
is not available until that job runs.

To download the coverage report from the job details page, add it to the
artifact `paths` as well as `reports`:

```yaml
artifacts:
  paths:
    - coverage/cobertura-coverage.xml
  reports:
    coverage_report:
      coverage_format: cobertura
      path: coverage/cobertura-coverage.xml
```

## Path resolution

Coverage reports use relative file paths. GitLab resolves these to absolute repository
paths by matching them against the files changed in the MR.

For JaCoCo, the matching process is:

1. Find all merge requests for the same pipeline ref.
1. For all changed files, collect the absolute paths.
1. For each relative path in the report, use the first matching absolute path.

For Cobertura, GitLab also uses the `<sources>` element to reconstruct paths:

1. Extract path segments from each `<source>` entry.
1. Combine each segment with the `filename` attribute of each `<class>` element.
1. Check if the candidate path exists in the repository.
1. Use the first match as the absolute path.

This automatic correction only works when `<source>` paths follow the format
`<CI_BUILDS_DIR>/<PROJECT_FULL_PATH>/...`.

### Path resolution example

For a C# project with a full path of `test-org/test-cs-project` and these files
relative to the project root:

```plaintext
Auth/User.cs
Lib/Utils/User.cs
```

With these `sources` in the Cobertura XML:

```xml
<sources>
  <source>/builds/test-org/test-cs-project/Auth</source>
  <source>/builds/test-org/test-cs-project/Lib/Utils</source>
</sources>
```

The parser extracts `Auth` and `Lib/Utils` from the `sources`, then combines each with the
`filename` attribute of each `<class>` element. For a class with `filename="User.cs"`, the
first candidate that matches a file in the repository is `Auth/User.cs`.

For each `<class>` element, the parser attempts up to 100 iterations. If no match is found,
the class is not included in the final coverage report.

## Troubleshooting

When working with coverage visualization, you might encounter the following issues.

### Diff annotations do not appear

Annotations might not appear for the following reasons:

- The pipeline has not completed. Annotations are generated after the pipeline finishes.
  Wait for the pipeline to complete, then reload the MR diff.
- The file is not in the MR diff. Annotations appear only on files changed in the MR,
  even if the report includes coverage data for other files.
- The file path in the report does not match the repository path. If path resolution
  fails, the annotation is silently skipped. To diagnose, download the coverage XML
  artifact and compare the `filename` attribute on a `<class>` element to the file's
  path in the repository relative to the project root.
- The project has multiple modules with duplicate relative paths. When paths are not
  unique across modules, GitLab cannot resolve which file the annotation belongs to.
  Ensure relative paths are unique across modules:

  ```diff
      src/main/java/org/acme/DemoExample.java
    - src/main/other-module/org/acme/DemoExample.java
    + src/main/other-module/org/acme/OtherDemoExample.java
  ```

- The `coverage` keyword is not configured. `artifacts:reports:coverage_report` does
  not produce a percentage in the MR widget. To display a coverage percentage, configure
  the `coverage` keyword separately.

### Metrics do not display for all changed files

This issue occurs when you create a new merge request from the same source branch but
with a different target branch. The pipeline uses diffs from the previous merge request
and does not display annotations for files not in that diff.

To fix this issue, wait until the new merge request is created, then rerun the pipeline.
