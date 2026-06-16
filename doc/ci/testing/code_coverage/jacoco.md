---
stage: Verify
group: Pipeline Execution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: Display line-by-line test coverage annotations in merge request diffs using JaCoCo XML reports.
title: JaCoCo coverage visualization
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/227345) in GitLab 17.3 [with a flag](../../../administration/feature_flags/_index.md) named `jacoco_coverage_reports`. Disabled by default.
- [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/170513) in GitLab 17.6. Feature flag `jacoco_coverage_reports` removed.

{{< /history >}}

Use JaCoCo coverage reports to display line-by-line coverage annotations in merge request
diffs. GitLab reads the JaCoCo XML report and annotates each changed line as covered (green)
or not covered (red).

Coverage visualization uses the [`artifacts:reports:coverage_report`](../../yaml/artifacts_reports.md#artifactsreportscoverage_report)
keyword. It does not display a coverage percentage in the MR widget or populate coverage history graphs.
To display a coverage percentage, configure the
[`coverage`](../../yaml/_index.md#coverage) keyword separately.

> [!note]
> Aggregated reports from multi-module projects are not supported. To contribute to
> aggregated report support, see [issue 491015](https://gitlab.com/gitlab-org/gitlab/-/issues/491015).

## Add a JaCoCo coverage job

Add a JaCoCo coverage job when you want to display line-by-line coverage annotations
in merge request diffs.

Prerequisites:

- A properly formatted [JaCoCo XML file](https://www.jacoco.org/jacoco/trunk/coverage/jacoco.xml)
  that provides [line coverage](https://www.eclemma.org/jacoco/trunk/doc/counters.html).

To add a JaCoCo coverage job:

1. Add a job to your `.gitlab-ci.yml` file with `artifacts:reports:coverage_report`
   set to `jacoco`. For example:

   ```yaml
   test-jdk11:
     stage: test
     image: maven:3.6.3-jdk-11
     script:
       - mvn $MAVEN_CLI_OPTS clean org.jacoco:jacoco-maven-plugin:prepare-agent test jacoco:report
     artifacts:
       reports:
         coverage_report:
           coverage_format: jacoco
           path: target/site/jacoco/jacoco.xml
   ```

1. Set `path` to the location of the generated JaCoCo XML report.

If the job generates multiple reports, use a
[wildcard in the artifact path](../../jobs/job_artifacts.md#with-wildcards).

## Coverage indicators

JaCoCo visualization uses
[instructions (C0 Coverage)](https://www.eclemma.org/jacoco/trunk/doc/counters.html),
represented as `ci` (covered instructions) in reports.

After the pipeline completes, coverage displays in the merge request diff view with
these indicators:

- Instructions covered (green): lines with at least one covered instruction (`ci > 0`)
- No instructions covered (red): lines without any covered instructions (`ci = 0`)
- No coverage information: lines not included in the coverage report

For example, with this report output:

```xml
<line nr="83" mi="2" ci="0" mb="0" cb="0"/>
<line nr="84" mi="2" ci="0" mb="0" cb="0"/>
<line nr="85" mi="2" ci="0" mb="0" cb="0"/>
<line nr="86" mi="2" ci="0" mb="0" cb="0"/>
<line nr="88" mi="0" ci="7" mb="0" cb="1"/>
```

The merge request diff view displays coverage as follows:

![Merge request diff view showing coverage indicators with red bars for uncovered lines and green bars for covered lines.](img/jacoco_coverage_example_v18_3.png)

In this example, lines 83-86 show red bars for uncovered code, line 88 shows a green bar
for covered code, and lines 87, 89-90 have no coverage data.

## Troubleshooting

For troubleshooting coverage visualization, including path resolution failures and
annotations that do not appear as expected, see
[coverage visualization troubleshooting](coverage_visualization.md#troubleshooting).

## Give feedback

JaCoCo coverage visualization is actively being improved. To report issues or suggest
improvements, leave your feedback in [issue 479804](https://gitlab.com/gitlab-org/gitlab/-/issues/479804).
