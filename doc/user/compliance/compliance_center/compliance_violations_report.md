---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Compliance violations report
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112111) to compliance violations report in GitLab 15.9.
> - Ability to create and edit compliance frameworks [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394950) in GitLab 16.0.

With the compliance violations report, you can see a high-level view of merge request activity for all projects in the group.

When you select a row in the compliance violations report, a drawer appears that provides:

- The project name and [compliance framework label](../../project/working_with_projects.md#add-a-compliance-framework-to-a-project),
  if the project has one assigned.
- A link to the merge request that introduced the violation.
- The merge request's branch path in the format `[source] into [target]`.
- A list of users that committed changes to the merge request.
- A list of users that commented on the merge request.
- A list of users that approved the merge request.
- The user that merged the merge request.

## View the compliance violations report

> - Target branch search [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358414) in GitLab 16.0.

Prerequisites:

- You must be an administrator or have the Owner role for the project or group.

To view the compliance violations report:

1. On the left sidebar, select **Search or go to** and find your project or group.
1. Select **Secure > Compliance center**.

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

| Icon                    | Severity level |
|:------------------------|:---------------|
| **{severity-critical}** | Critical       |
| **{severity-high}**     | High           |
| **{severity-medium}**   | Medium         |
| **{severity-low}**      | Low            |
| **{severity-info}**     | Info           |

<!-- vale gitlab_base.SubstitutionWarning = YES -->

### Violation types

From [GitLab 14.10](https://gitlab.com/groups/gitlab-org/-/epics/6870), these are the available compliance violations.

| Violation                         | Severity level | Category                                      | Description                                                                                                                                                                                                                                            |
|:----------------------------------|:---------------|:----------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Author approved merge request     | High           | [Separation of duties](#separation-of-duties) | Author of the merge request approved their own merge request. For more information, see [Prevent approval by author](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author).                                                   |
| Committers approved merge request | High           | [Separation of duties](#separation-of-duties) | Committers of the merge request approved the merge request they contributed to. For more information, see [Prevent approvals by users who add commits](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits). |
| Fewer than two approvals          | High           | [Separation of duties](#separation-of-duties) | Merge request was merged with fewer than two approvals. For more information, see [Merge request approval rules](../../project/merge_requests/approvals/rules.md).                                                                                     |

#### Separation of duties

GitLab supports a separation of duties policy between users who create and approve merge requests. Our criteria for the
separation of duties is:

- [A merge request author is **not** allowed to approve their merge request](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author).
- [A merge request committer is **not** allowed to approve a merge request they have added commits to](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).
- [The minimum number of approvals required to merge a merge request is **at least** two](../../project/merge_requests/approvals/rules.md).

## Export a report of merge request compliance violations on projects in a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356791) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `compliance_violation_csv_export`. Disabled by default.
> - [Enabled on GitLab.com and GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/424447) in GitLab 16.5.
> - [Feature flag `compliance_violation_csv_export`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142568) removed in GitLab 16.9.

Export a report of merge request compliance violations on merge requests belonging to projects in a group. Reports:

- Do not use filters on the violations report.
- Are truncated at 15 MB so the email attachment is not too large.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export a report of merge request compliance violations for projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export violations report**.

A report is compiled and delivered to your email inbox as an attachment.
