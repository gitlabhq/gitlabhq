---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Compliance violations report

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

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

## View the compliance violations report for a group

> - Target branch search [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358414) in GitLab 16.0.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the compliance violations report:

1. On the left sidebar, select **Search or go to** and find your group.
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

<!-- vale gitlab.SubstitutionWarning = NO -->

| Icon                    | Severity level |
|:------------------------|:---------------|
| **{severity-critical}** | Critical       |
| **{severity-high}**     | High           |
| **{severity-medium}**   | Medium         |
| **{severity-low}**      | Low            |
| **{severity-info}**     | Info           |

<!-- vale gitlab.SubstitutionWarning = YES -->

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
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/424447) in GitLab 16.5.
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

## Chain of Custody report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213364) in GitLab 13.3.
> - Chain of Custody reports sent using email [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/342594) in GitLab 15.3 with a flag named `async_chain_of_custody_report`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/370100) in GitLab 15.5. Feature flag `async_chain_of_custody_report` removed.
> - Chain of Custody report includes all commits (instead of just merge commits) [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267601) in GitLab 15.9 with a flag named `all_commits_compliance_report`. Disabled by default.
> - [Generally available](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112092) in GitLab 15.9. Feature flag `all_commits_compliance_report` removed.

The Chain of Custody report provides a 1 month trailing window of all commits to a project under the group.

To generate the report for all commits, GitLab:

1. Fetches all projects under the group.
1. For each project, fetches the last 1 month of commits. Each project is capped at 1024 commits. If there are more than
   1024 commits in the 1-month window, they are truncated.
1. Writes the commits to a CSV file. The file is truncated at 15 MB because the report is emailed as an attachment
   (GitLab 15.5 and later).

The report includes:

- Commit SHA.
- Commit author.
- Committer.
- Date committed.
- Group.
- Project.

If the commit has a related merge commit, then the following are also included:

- Merge commit SHA.
- Merge request ID.
- User who merged the merge request.
- Merge date.
- Pipeline ID.
- Merge request approvers.

### Generate Chain of Custody report

To generate the Chain of Custody report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export chain of custody report**.

Depending on your version of GitLab, the Chain of Custody report is either sent through email or available for download.

### Generate commit-specific Chain of Custody report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267629) in GitLab 13.6.
> - Support for including all commits instead of only merge commits [added](https://gitlab.com/gitlab-org/gitlab/-/issues/393446) in GitLab 15.10.

You can generate a commit-specific Chain of Custody report for a given commit SHA. This report provides only the
details for the provided commit SHA.

To generate a commit-specific Chain of Custody report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export custody report of a specific commit**.
1. Enter the commit SHA, and then select **Export custody report**.

Depending on your version of GitLab, the Chain of Custody report is either sent through email or available for download.

Alternatively, use a direct link: `https://gitlab.com/groups/<group-name>/-/security/merge_commit_reports.csv?commit_sha={optional_commit_sha}`,
passing in an optional value to the `commit_sha` query parameter.
