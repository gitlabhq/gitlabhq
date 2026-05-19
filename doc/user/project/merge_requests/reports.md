---
stage: Security Risk Management
group: Security Insights
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
description: View findings in the merge request Reports tab.
title: Merge request reports
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Introduced](https://gitlab.com/groups/gitlab-org/-/epics/20406) in GitLab 19.0 [with a flag](../../../administration/feature_flags/_index.md) named `mr_reports_tab`. Disabled by default.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

The **Reports** tab on a merge request shows detailed findings from CI/CD
pipeline scans. The tab displays security scan findings,
license compliance results, and code quality reports in
a dedicated full-page view.

## Security scan report

The security scan report provides a summary of the changes that would occur in the findings if the source branch were merged.

For example, consider two pipelines with these scan results:

- The target branch pipeline detects two vulnerabilities identified as `V1` and `V2`.
- The source branch pipeline detects two vulnerabilities identified as `V1` and `V3`.

The security scan report shows the following results:

- `V1` exists on both branches so is not shown in the report.
- `V2` appears in the report as **fixed**.
- `V3` appears in the report as **added**.

For the security scan report to show the differences between the source branch and the target branch, you must have security reports from both branches. The system checks the 10 most recent commits on the target branch for valid security pipelines. For each commit, up to 10 of the most recent pipelines are checked for a security report.

This approach ensures that even if a commit skips the pipeline, a valid security report from an earlier commit is found. If no security report is found, all findings are listed as new. Before you enable security scanning in merge requests, ensure that security scanning is enabled for the default branch.

For each security report type, the report displays the first 25 added and 25 fixed findings, sorted by severity. To see all findings on the source branch of the merge request, select **View all pipeline findings**.

### View security scan findings

Prerequisites:

- You must have at least the Developer role for the project.
- You must [configure security scanning](../../application_security/detect/security_configuration.md)
  for the project.
- Security scanning must be enabled on the default branch.

To view security scan findings:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Merge requests**.
1. Select a merge request.
1. Select the **Reports** tab.
1. Select **Security scan**.

## License compliance report

The license compliance report shows licenses detected in your project's
dependencies by comparing the source branch pipeline results with the target
branch pipeline results.

Licenses are grouped into three categories:

- **New licenses**: Licenses detected in the source branch that do not exist
  in the target branch.
- **Existing licenses**: Licenses that exist in both branches.
- **Removed licenses**: Licenses that exist in the target branch but not in
  the source branch.

For each license, the report shows the following information:

- License name and classification (allowed, denied, or unknown)
- Number of dependencies using the license
- List of affected dependencies with package manager and version information

License classifications are determined by your project's
[license approval policies](../../compliance/license_approval_policies.md).

### View license compliance findings

Prerequisites:

- You must have at least the Developer role for the project.
- You must have [license scanning](../../compliance/license_scanning_of_cyclonedx_files/_index.md)
  configured for your project.

To view license compliance findings:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Merge requests**.
1. Select a merge request.
1. Select the **Reports** tab.
1. Select **License compliance**.

## Code quality report

The code quality report shows code quality violations detected in your merge request
by comparing the source branch pipeline results with the target branch pipeline
results. The report is available if a report from the target branch is available
for comparison.

The report shows:

- **New violations**: Code quality violations detected in the source branch that
  do not exist in the target branch.
- **Resolved violations**: Code quality violations that exist in the target
  branch but not in the source branch. Resolved violations are marked with a badge.

Each violation shows the following information:

- Description of the code quality issue
- Severity level (blocker, critical, major, minor, or info)
- File path and line number where the violation occurs
- Check name (the rule or linter that detected the violation)

Duplicated violations, with identical fingerprints, are removed. Only a single entry is displayed.

### View code quality findings

Prerequisites:

- Developer, Maintainer, or Owner role
- [Code quality scanning](../../../ci/testing/code_quality.md) configured for
  your project

To view code quality findings:

1. In the left sidebar, select **Search or go to** and find your project.
1. Select **Code** > **Merge requests**.
1. Select a merge request.
1. Select the **Reports** tab.
1. Select **Code quality**.

## Troubleshooting

When security scanning is enabled, you might encounter the following issues.

### Dismissed vulnerabilities are visible in the security scan report

When you view the security widget in a merge request, the widget might include vulnerabilities
that are already dismissed.

No solution is available for this issue. To track the proposed solution, see
[issue 411235](https://gitlab.com/gitlab-org/gitlab/-/issues/411235).
