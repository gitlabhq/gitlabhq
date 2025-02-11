---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance standards adherence dashboard
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125875) GraphQL APIs in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `compliance_adherence_report`. Disabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125444) compliance standards adherence dashboard in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `adherence_report_ui`. Disabled by default.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/414495) in GitLab 16.5.
> - [Feature flag `compliance_adherence_report` and `adherence_report_ui`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137398) removed in GitLab 16.7.
> - Standards adherence filtering [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413734) in GitLab 16.7.
> - Standards adherence grouping [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413735) in GitLab 16.9.
> - Standards adherence grouping by standards that a check belongs to and grouping by projects that a check belongs to [added](https://gitlab.com/gitlab-org/gitlab/-/issues/413735) in GitLab 16.10.
> - **Last Scanned** column [renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/439545) to **Date since last status change** in GitLab 16.10.
> - DAST scanner check [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440721) to GitLab Standard in GitLab 17.6.
> - SAST scanner check [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/440722) to GitLab Standard in GitLab 17.6.

The compliance standards adherence dashboard lists the adherence status of projects complying to the _GitLab standard_.

When a project is added, or an associated project or group setting is changed, an adherence scan is run on that project to update the standards adherence for that project.
The field in the **Date since last status change** column reflects the date of the initial status and any subsequent changes to the status.

## View the compliance standards adherence dashboard

Prerequisites:

- You must be an administrator or have the Owner role for the project or group.

To view the compliance standards adherence dashboard:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > Compliance center**.

You can filter the compliance standards adherence dashboard on:

- The project that the check was performed on.
- The type of check that was performed on a project.
- The standard that the check belongs to.

You can group the compliance standards adherence dashboard on:

- The project that the check was performed on.
- The type of check that was performed on a project.
- The standard that the check belongs to.

## GitLab standard

The GitLab standard consists of the following rules:

- Prevent authors as approvers.
- Prevent committers as approvers.
- At least two approvals.
- Static Application Security Testing (SAST) scanner artifact.
- Dynamic Application Security Testing (DAST) scanner artifact.

### Prevent authors as approvers

To comply with the GitLab standard, you must prevent users from approving their own merge requests. For more information,
see [Prevent approval by author](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author).

On GitLab Self-Managed, when instance-level setting for [prevent approval by author](../../../administration/merge_requests_approvals.md)
is updated, the adherence status for all the projects on the instance is not updated automatically.
To update the adherence status for these projects, the group-level or the project-level setting must be updated.

### Prevent committers as approvers

To comply with the GitLab standard, you must prevent users from approving merge requests where they've added commits. For
more information, see [Prevent approvals by users who add commits](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).

On GitLab Self-Managed, when instance-level setting for [prevent approvals by users who add commits](../../../administration/merge_requests_approvals.md)
is updated, the adherence status for all the projects on the instance is not updated automatically.
To update the adherence status for these projects, the group-level or the project-level setting must be updated.

### At least two approvals

To comply with the GitLab standard, you must have at least two users approve a merge request to get it merged. For more
information, see [Merge request approval rules](../../project/merge_requests/approvals/rules.md).

### SAST scanner artifact

To comply with the GitLab standard, you must have the SAST scanner enabled, configured, and producing an artifact in the project's pipeline. For more
information, see [Static Application Security Testing (SAST)](../../application_security/sast/_index.md).

### DAST scanner artifact

To comply with the GitLab standard, you must have the DAST scanner enabled, configured, and producing an artifact in the project's pipeline. For more
information, see [DAST on-demand scan](../../application_security/dast/on-demand_scan.md).

## SOC 2 standard

> - At least one non-author approval SOC 2 check [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/433201) in GitLab 16.10.

The SOC 2 standard consists of one rule:

- At least one non-author approval.

### At least one non-author approval

To comply with the SOC 2 standard, you must:

- Prevent users from approving their own merge requests. For more information, see
  [Prevent approval by author](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author).
- Prevent users from approving merge requests where they've added commits, see
  [Prevent approvals by users who add commits](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).
- At least one approval is required, see [Merge request approval rules](../../project/merge_requests/approvals/rules.md).

These settings are available for an entire instance. However, when these settings are updated at the instance level,
the adherence status for all the projects on the instance is not updated automatically. To update the adherence status
for these projects, you must update the group-level or project-level setting. For more information on the instance-level settings, see:

- [Prevent approval by author](../../../administration/merge_requests_approvals.md).
- [Prevent approvals by users who add commits](../../../administration/merge_requests_approvals.md).

## Export compliance standards adherence report for projects in a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/413736) in GitLab 16.8 [with a flag](../../../administration/feature_flags.md) named `compliance_standards_adherence_csv_export`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142568) in GitLab 16.9. Feature flag `compliance_standards_adherence_csv_export` removed.

Exports the contents of a standards adherence report for projects in a group. Reports are truncated at 15 MB to avoid a large email attachment.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export the compliance standards adherence report for projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export standards adherence report**.

A report is compiled and delivered to your email inbox as an attachment.
