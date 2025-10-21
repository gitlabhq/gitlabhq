---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance violations report
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed, GitLab Dedicated

{{< /details >}}

{{< history >}}

- [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112111) to compliance violations report in GitLab 15.9.
- Ability to create and edit compliance frameworks [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394950) in GitLab 16.0.
- New dynamic compliance violations report [introduced](https://gitlab.com/groups/gitlab-org/-/epics/12774) in GitLab 18.2 [with a flag](../../../administration/feature_flags/_index.md) named `compliance_violations_report` and `enable_project_compliance_violations`. Disabled by default.
- Feature flags `compliance_violations_report` and `enable_project_compliance_violations` [enabled by default](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201027) in GitLab 18.3.
- Feature flags `compliance_violations_report` and `enable_project_compliance_violations` [removed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/201027) in GitLab 18.5.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.
This feature is available for testing, but not ready for production use. For production use, continue to use the
[static compliance violations report](#static-compliance-violations-report).

{{< /alert >}}

Use the compliance violations report to see a comprehensive view of compliance violations across all projects in
your group. The report provides detailed information about violated controls, associated audit events, and allows you
to manage violation statuses.

## View the compliance violations report

Prerequisites:

- You must be an administrator or have the Owner role for the project or group.

To view the compliance violations report:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure** > **Compliance center**.

The compliance violations report displays:

- **Status**: The current status of the violation. For example, Needs Review, Resolved, or Dismissed.
- **Violated control and framework**: The specific compliance control that was violated and its associated framework.
- **Audit Event**: Details about the event that triggered the violation.
- **Project**: The project where the violation occurred.
- **Date detected**: When the violation was identified.
- **Action**: Link to view detailed information about the violation.

In the report, you can:

- Sort the report by selecting column headers.
- Change the status of violations using the status dropdown list.
- Navigate through multiple pages of violations by using pagination.
- View detailed information about each violation.
- Export the report as a CSV file.

## Violation details

When you select **Details** for a specific violation, you can view:

- The violation ID and status.
- Location (project) where the violation occurred.
- Comprehensive audit event information including:
  - Event author.
  - Event target.
  - Event details.
  - IP address.
  - Target type.
- Violated control information including:
  - Control name and description.
  - Associated compliance framework.
  - Requirements.
- Fix suggestions with links to resolve the violation.

## Manage violation statuses

You can update the status of compliance violations to track their remediation progress. Available statuses include:

- **Needs Review**: Default status for new violations
- **In Progress**: Violation is being addressed
- **Resolved**: Violation has been remediated
- **Dismissed**: Violation has been reviewed and dismissed

To change a violation status:

1. In the compliance violations report, locate the violation you want to update.
1. Select the current status dropdown list in the **Status** column.
1. Choose the new status from the dropdown list menu.

The status updates immediately and is reflected in the report.

## Export compliance violations report

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/551244) in GitLab 18.3.

{{< /history >}}

Export a CSV report of compliance violations for all projects in a group. The exported report includes:

- Detected at (DateTime most current first)
- Violation ID
- Status
- Framework
- Compliance Control
- Compliance Requirement
- Audit Event Author
- Audit Event Type
- Audit Event Name
- Audit Event Message
- Project ID

Reports:

- Are truncated at 15 MB so the email attachment is not too large.
- Include all violations regardless of current filters applied to the web interface.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export a compliance violations report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure** > **Compliance center**.
1. In the upper-right corner, select **Export**.
1. Select **Export violations report**.

A report is compiled and delivered to your email inbox as an attachment.

## Static compliance violations report

{{< alert type="warning" >}}

This feature was [deprecated](https://gitlab.com/gitlab-org/gitlab/-/issues/551236) in GitLab 18.2
and is planned for removal in 18.8.

{{< /alert >}}

The static compliance violations report provides a high-level view of merge request activity for all projects in the group.

When you select a row in the static compliance violations report, a drawer appears that provides:

- The project name and [compliance framework label](../../project/working_with_projects.md#add-a-compliance-framework-to-a-project),
  if the project has one assigned.
- A link to the merge request that introduced the violation.
- The merge request's branch path in the format `[source] into [target]`.
- A list of users that committed changes to the merge request.
- A list of users that commented on the merge request.
- A list of users that approved the merge request.
- The user that merged the merge request.

### View the static compliance violations report

{{< history >}}

- Target branch search [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358414) in GitLab 16.0.

{{< /history >}}

Prerequisites:

- You must be an administrator or have the Owner role for the project or group.

To view the static compliance violations report:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure** > **Compliance center**.

You can sort the compliance report on:

- Severity level.
- Type of violation.
- Merge request title.

You can filter the compliance violations report on:

- The project that the violation was found on.
- The date range of violation.
- The target branch of the violation.

Select a row to see details of the compliance violation.

### Severity levels

Each compliance violation has one of the following severities.

<!-- vale gitlab_base.SubstitutionWarning = NO -->

| Icon                                  | Severity level |
|:--------------------------------------|:---------------|
| {{< icon name="severity-critical" >}} | Critical       |
| {{< icon name="severity-high" >}}     | High           |
| {{< icon name="severity-medium" >}}   | Medium         |
| {{< icon name="severity-low" >}}      | Low            |
| {{< icon name="severity-info" >}}     | Info           |

<!-- vale gitlab_base.SubstitutionWarning = YES -->

### Violation types

| Violation                         | Severity level | Category                                      | Description                                                                                                                                                                                                                                            |
|:----------------------------------|:---------------|:----------------------------------------------|:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Author approved merge request     | High           | [Separation of duties](#separation-of-duties) | Author of the merge request approved their own merge request. For more information, see [Prevent approval by merge request creator](../../project/merge_requests/approvals/settings.md#prevent-approval-by-merge-request-creator).                     |
| Committers approved merge request | High           | [Separation of duties](#separation-of-duties) | Committers of the merge request approved the merge request they contributed to. For more information, see [Prevent approvals by users who add commits](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits). |
| Fewer than two approvals          | High           | [Separation of duties](#separation-of-duties) | Merge request was merged with fewer than two approvals. For more information, see [Merge request approval rules](../../project/merge_requests/approvals/rules.md).                                                                                     |

#### Separation of duties

GitLab supports a separation of duties policy between users who create and approve merge requests. Our criteria for the
separation of duties is:

- [A merge request creator is not allowed to approve their merge request](../../project/merge_requests/approvals/settings.md#prevent-approval-by-merge-request-creator).
- [A merge request committer is not allowed to approve a merge request they have added commits to](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).
- [The minimum number of approvals required to merge a merge request is at least two](../../project/merge_requests/approvals/rules.md).

### Export a report of merge request compliance violations on projects in a group

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356791) in GitLab 16.4 [with a flag](../../../administration/feature_flags/_index.md) named `compliance_violation_csv_export`. Disabled by default.
- [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/424447) in GitLab 16.5.
- [Feature flag `compliance_violation_csv_export`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142568) removed in GitLab 16.9.

{{< /history >}}

Export a report of merge request compliance violations on merge requests belonging to projects in a group. Reports:

- Do not use filters on the violations report.
- Are truncated at 15 MB so the email attachment is not too large.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export a report of merge request compliance violations for projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure** > **Compliance center**.
1. In the upper-right corner, select **Export**.
1. Select **Export violations report**.

A report is compiled and delivered to your email inbox as an attachment.
