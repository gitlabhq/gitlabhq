---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Security scanning results
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/490334) in GitLab 17.9 [with a feature flag](../../../administration/feature_flags/_index.md) named `dependency_scanning_for_pipelines_with_cyclonedx_reports`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/490332) in GitLab 17.9.
- Feature flag `dependency_scanning_for_pipelines_with_cyclonedx_reports` removed in 17.10.

{{< /history >}}

View and act on the results of pipeline security scanning in GitLab. Select security scanners run in
a pipeline and output security reports. The contents of these reports are processed and presented in
GitLab.

Security scanning must be configured for your project to generate results.
For information about configuring security scanners, see [Security configuration](security_configuration.md).

Key terminology for understanding security scan results:

Finding
: A finding is a potential vulnerability identified in a development branch. A finding becomes a
  vulnerability when the branch is merged into the default branch.
: Findings expire, either when the related CI/CD job artifact expires, or 90 days after the
  pipeline is created, even if the related job artifacts are locked.

Vulnerability
: A vulnerability is a software security weakness identified in the default branch.
: Vulnerability records persist until they are [archived](../vulnerability_archival/_index.md),
  even if the vulnerability is no longer detected in the default branch.

Vulnerabilities identified in the default branch are listed in the [vulnerability report](../vulnerability_report/_index.md).

## Security report artifacts

Security scanners run in branch pipelines and, if enabled, merge request pipelines. Each security
scanner outputs a security report artifact containing details of all findings or vulnerabilities detected by
the specific security scanner.

Security reports from [child pipelines](../../../ci/pipelines/downstream_pipelines.md#view-child-pipeline-reports-in-merge-requests)
are included in pipeline security reports and merge request reports.

In a development (non-default) branch, findings include any vulnerabilities present in the target
branch when the development branch was created.

Findings expire either when the related CI/CD job artifact expires, or 90 days after the
pipeline is created, even if the related job artifacts are locked.
Expired findings are not shown in the pipeline's **Security** tab. To reproduce them, re-run the pipeline.

### Download a security report

{{< details >}}

- Tier: Ultimate

{{< /details >}}

You can download a security report, for example to analyze outside GitLab or for archival
purposes. A security report is a JSON file.

Prerequisites:

- The Security Manager, Developer, Maintainer, or Owner role for the project.

To download a security report:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Build** > **Pipelines**.
1. Select the pipeline.
1. Select the **Security** tab.
1. Select **Download results**, then the desired security report.

The selected security report is downloaded to your device.

![List of security reports](img/security_report_v18_1.png)

## Pipeline security report

{{< details >}}

- Tier: Ultimate

{{< /details >}}

The pipeline security report contains details of all findings or vulnerabilities detected in the
branch. For a pipeline run against the default branch, all vulnerabilities in the pipeline security
report are also in the vulnerability report.

![List of findings in the branch](img/pipeline_security_report_v18_1.png)

### View pipeline security report

View the pipeline security report to see details of all findings or vulnerabilities detected in the
branch.

Prerequisites:

- The Security Manager, Developer, Maintainer, or Owner role for the project.

To view a pipeline security report:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Build** > **Pipelines**.
1. Select the latest pipeline.

To see details of a finding or vulnerability, select its description.

### Create an issue

Create an issue to track, document, and manage the remediation work for a finding or vulnerability.

Prerequisites:

- The Security Manager, Developer, Maintainer, or Owner role for the project.

To create an issue:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Build** > **Pipelines**.
1. Select the pipeline.
1. Select the **Security** tab.
1. Select a finding's description.
1. Select **Create issue**.

An issue is created in the project, with the description copied from the finding or vulnerability's
description.

### Change status

You can change the status of a finding or vulnerability in the pipeline's
security tab. Any changes made to a finding persist when the branch is merged into the default
branch.

Prerequisites:

- The Maintainer role for the project or the `admin_vulnerability` custom permission.

To change the status of findings or vulnerabilities:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Build** > **Pipelines**.
1. Select the latest pipeline.
1. Select the **Security** tab.
1. In the finding report:

     1. Select the findings or vulnerabilities you want to change.

        - To select individual findings or vulnerabilities, select the checkbox beside each.
        - To select all findings or vulnerabilities on the page, select the checkbox in the table
          header.

     1. In the **Select action** dropdown list, select either **Dismissed** or **Needs Triage**.
     1. Select **Change status**.

### Download a security report

{{< details >}}

- Tier: Ultimate

{{< /details >}}

You can download a security report, for example to analyze outside GitLab or for archival
purposes. A security report is a JSON file.

Prerequisites:

- The Security Manager, Developer, Maintainer, or Owner role for the project.

To download a security report:

1. In the top bar, select **Search or go to** and find your project.
1. In the left sidebar, select **Build** > **Pipelines**.
1. Select the pipeline.
1. Select the **Security** tab.
1. Select **Download results**, then the desired security report.

The selected security report is downloaded to your device.

![List of security reports](img/security_report_v18_1.png)

## Merge request reports

For security scan results in a merge request, see [merge request reports](../../project/merge_requests/reports.md).

## Troubleshooting

When working with security scanning, you might encounter the following issues.

### Report parsing and scan ingestion errors

> [!note]
> These steps are to be used by GitLab Support to reproduce such errors.

Some security scans may result in errors in the **Security** tab of the pipeline related to report parsing or scan ingestion. If it is not possible to get a copy of the project from the user, you can reproduce the error using the report generated from the scan.

To recreate the error:

1. Obtain a copy of the report from the user. In this example, `gl-sast-report.json`.
1. Create a project.
1. Commit the report to the repository.
1. Add your `.gitlab-ci.yml` file and have the report as an artifact in a job.

   For example, to reproduce an error caused by a SAST job:

   ```yaml
   sample-job:
     script:
       - echo "Testing report"
     artifacts:
       reports:
         sast: gl-sast-report.json
   ```

1. After the pipeline completes, check the content of the pipeline's **Security** tab for errors.

You can replace `sast: gl-sast-report.json` with the respective [`artifacts:reports`](../../../ci/yaml/_index.md#artifactsreports) type and the correct JSON report filename depending on the scan that generated the report.
