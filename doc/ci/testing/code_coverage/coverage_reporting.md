---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Display a test coverage percentage in merge requests, analytics, and badges.
title: Coverage reporting
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

Use the [`coverage`](../../yaml/_index.md#coverage) keyword to extract a coverage percentage
from your test job's log output and display it in merge requests and analytics.

This keyword displays a coverage percentage only. It does not produce line-by-line annotations
in the MR diff. To display line annotations, configure
[`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)
separately.

## Configure coverage reporting

To configure coverage reporting:

1. Add the `coverage` keyword to your job with a regular expression that matches
   your test tool's output:

   ```yaml
   test:
     script:
       - pytest --cov
     coverage: '/TOTAL.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
   ```

1. To aggregate coverage from multiple jobs, add the `coverage` keyword to each job.

### Coverage regex patterns

The following regex patterns match output from common test coverage tools.
Test these carefully, as tool output formats can change over time.

{{< tabs >}}

{{< tab title="Python and Ruby" >}}

| Tool           | Language | Command        | Regex pattern |
| -------------- | -------- | -------------- | ------------- |
| pytest-cov     | Python   | `pytest --cov` | `/TOTAL.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |
| Simplecov-html | Ruby     | `rspec spec`   | `/Line\sCoverage:\s\d+\.\d+%/` |

{{< /tab >}}

{{< tab title="C/C++ and Rust" >}}

| Tool      | Language | Command           | Regex pattern |
| --------- | -------- | ----------------- | ------------- |
| gcovr     | C/C++    | `gcovr`           | `/^TOTAL.*\s+(\d+\%)$/` |
| tarpaulin | Rust     | `cargo tarpaulin` | `/^\d+.\d+% coverage/` |

{{< /tab >}}

{{< tab title="Java and JVM" >}}

| Tool      | Language    | Command                            | Regex pattern |
| --------- | ----------- | ---------------------------------- | ------------- |
| JaCoCo    | Java/Kotlin | `./gradlew test jacocoTestReport`  | `/Total.*?([0-9]{1,3})%/` |
| Scoverage | Scala       | `sbt coverage test coverageReport` | `/(?i)total.*? (100(?:\.0+)?\%\|[1-9]?\d(?:\.\d+)?\%)$/` |

{{< /tab >}}

{{< tab title="Node.js" >}}

| Tool      | Command                                    | Regex pattern |
| --------- | ------------------------------------------ | ------------- |
| tap       | `tap --coverage-report=text-summary`       | `/^Statements\s*:\s*([^%]+)/` |
| nyc       | `nyc npm test`                             | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| jest      | `jest --ci --coverage`                     | `/All files[^\|]*\|[^\|]*\s+([\d\.]+)/` |
| node:test | `node --experimental-test-coverage --test` | `/all files[^\|]*\|[^\|]*\s+([\d\.]+)/` |

{{< /tab >}}

{{< tab title="PHP" >}}

| Tool    | Command                                  | Regex pattern |
| ------- | ---------------------------------------- | ------------- |
| pest    | `pest --coverage --colors=never`         | `/Statement coverage[A-Za-z\.*]\s*:\s*([^%]+)/` |
| phpunit | `phpunit --coverage-text --colors=never` | `/^\s*Lines:\s*\d+.\d+\%/` |

{{< /tab >}}

{{< tab title="Go" >}}

| Tool              | Command                                                                    | Regex pattern |
| ----------------- | -------------------------------------------------------------------------- | ------------- |
| go test (single)  | `go test -cover`                                                           | `/coverage: \d+.\d+% of statements/` |
| go test (project) | `go test -coverprofile=cover.profile && go tool cover -func cover.profile` | `/total:\s+\(statements\)\s+\d+.\d+%/` |

{{< /tab >}}

{{< tab title=".NET and PowerShell" >}}

| Tool        | Language   | Command       | Regex pattern |
| ----------- | ---------- | ------------- | ------------- |
| OpenCover   | .NET       | None          | `/(Visited Points).*\((.*)\)/` |
| dotnet test | .NET       | `dotnet test` | `/Total\s*\|*\s(\d+(?:\.\d+)?)/` |
| Pester      | PowerShell | None          | `/Covered \d{1,3}[.,]?\d{0,2}%/` |

{{< /tab >}}

{{< tab title="Elixir" >}}

| Tool        | Command            | Regex pattern |
| ----------- | ------------------ | ------------- |
| excoveralls | None               | `/\[TOTAL\]\s+(\d+\.\d+)%/` |
| mix         | `mix test --cover` | `/\d+.\d+\%\s+\|\s+Total/` |

{{< /tab >}}

{{< /tabs >}}

## Add a coverage check approval rule

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

You can require specific users or a group to approve merge requests that reduce the project's test coverage.

Prerequisites:

- Configure coverage reporting.

To add a `Coverage-Check` approval rule:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Settings** > **Merge requests**.
1. Under **Merge request approvals**, do one of the following:
   - Next to the `Coverage-Check` approval rule, select **Enable**.
   - For manual setup, select **Add approval rule**, then enter `Coverage-Check` as the **Rule name**.
1. Select a **Target branch**.
1. Set the number of **Required number of approvals**.
1. Select the **Users** or **Groups** to provide approval.
1. Select **Save changes**.

> [!note]
> The `Coverage-Check` approval rule requires approval when the merge base pipeline contains
> no coverage data, even if the merge request improves overall coverage.

## View coverage history

You can track coverage trends for your project or group over time.

### For a project

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Analyze** > **Repository analytics**.
1. From the dropdown list, select the job you want to view historical data for.
1. Optional. To download the data, select **Download raw data (.csv)**.

### For a group

{{< details >}}

- Tier: Premium, Ultimate

{{< /details >}}

1. In the top bar, select **Search or go to** and find your group.
1. In the left sidebar, select **Analyze** > **Repository analytics**.
1. Optional. To download the data, select **Download historic test coverage data (.csv)**.

## Display coverage badges

To add a coverage badge to your project, see
[test coverage report badges](../../../user/project/badges.md#test-coverage-report-badges).

## Troubleshooting

When working with coverage reporting, you might encounter the following issues.

### Coverage percentage does not appear in the MR widget

The `coverage` keyword extracts a percentage from your job's log output using a regular
expression. If the percentage does not appear:

- Verify your regex matches your tool's actual output. Copy a line from the job log and
  test it against your regex.
- Some tools output ANSI color codes that break regex matching. If your tool does not
  support disabling color output, strip the codes before parsing:

  ```shell
  lein cloverage | perl -pe 's/\e\[?.*?[\@-~]//g'
  ```

- Check that the job completed successfully. Coverage is only extracted from successful jobs.
- Coverage output from child pipelines is not recorded. For details, see
  [issue 280818](https://gitlab.com/gitlab-org/gitlab/-/issues/280818).

> [!note]
> The `coverage` keyword only shows a percentage in the MR widget. For line-by-line
> annotations in the diff, configure
> [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)
> separately.
