---
type: reference, howto
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Compliance report **(ULTIMATE)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36524) in GitLab 12.8 as Compliance Dashboard.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/299360) to compliance report in GitLab 14.2.

Compliance report gives you the ability to see a group's merge request activity. It provides a
high-level view for all projects in the group. For example, code approved for merging into
production.

You can use the report to:

- Get an overview of the latest merge request for each project.
- See if merge requests were approved and by whom.
- See merge request authors.
- See the latest [CI/CD pipeline](../../../ci/pipelines/index.md) result for each merge request.

## View the compliance report for a group

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the compliance report:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Compliance report**.

NOTE:
The compliance report shows only the latest merge request on each project.

## Merge request drawer

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299357) in GitLab 14.1.

When you select a row, a drawer is shown that provides further details about the merge
request:

- Project name and [compliance framework label](../../project/settings/index.md#compliance-frameworks),
  if the project has one assigned.
- Link to the merge request.
- The merge request's branch path in the format `[source] into [target]`.
- A list of users that committed changes to the merge request.
- A list of users that commented on the merge request.
- A list of users that approved the merge request.
- The user that merged the merge request.

## Approval status and separation of duties

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217939) in GitLab 13.3.

We support a separation of duties policy between users who create and approve merge requests.
The approval status column can help you identify violations of this policy.
Our criteria for the separation of duties is as follows:

- [A merge request author is **not** allowed to approve their merge request](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author)
- [A merge request committer is **not** allowed to approve a merge request they have added commits to](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits)
- [The minimum number of approvals required to merge a merge request is **at least** two](../../project/merge_requests/approvals/rules.md)

The **Approval status** column shows you at a glance whether a merge request is complying with the above.
This column has four states:

| State | Description |
|:------|:------------|
| Empty | The merge request approval status is unknown |
| ![Failed](img/failed_icon_v13_3.png) | The merge request **does not** comply with any of the above criteria |
| ![Warning](img/warning_icon_v13_3.png) | The merge request complies with **some** of the above criteria |
| ![Success](img/success_icon_v13_3.png) | The merge request complies with **all** of the above criteria |

If you see a non-success state, review the criteria for the merge request's project to ensure it complies with the separation of duties.

## Chain of Custody report

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213364) in GitLab 13.3.

The Chain of Custody report allows customers to export a list of merge commits within the group.
The data provides a comprehensive view with respect to merge commits. It includes the merge commit SHA,
merge request author, merge request ID, merge user, pipeline ID, group name, project name, and merge request approvers.
Depending on the merge strategy, the merge commit SHA can be a merge commit, squash commit, or a diff head commit.

To download the Chain of Custody report:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Compliance report**.
1. Select **List of all merge commits**.

### Commit-specific Chain of Custody Report

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267629) in GitLab 13.6.

You can generate a commit-specific Chain of Custody report for a given commit SHA.

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Compliance report**.
1. At the top of the compliance report, to the right of **List of all merge commits**, select the down arrow (**{angle-down}**).
1. Enter the merge commit SHA, and then select **Export commit custody report**.
   SHA and then select **Export commit custody report**.

NOTE:
The Chain of Custody report download is a CSV file, with a maximum size of 15 MB.
The remaining records are truncated when this limit is reached.

## Merge request violations

> Introduced in GitLab 14.6. [Deployed behind the `compliance_violations_report` flag](../../../administration/feature_flags.md). Disabled by default.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available,
ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named `compliance_violations_report`.
The feature is not ready for production use.

Merge request violations provide a view of all the [separation of duties](#approval-status-and-separation-of-duties) compliance violations
that exist in projects in a specific group. For each separation of duties compliance violation, you can see:

- A list of compliance violations.
- The severity of each compliance violation.
- Reason for the compliance violation.
- A link to the merge request that caused the compliance violation.

Merge request violations can only be access in the GitLab UI, but issues are tracking adding:

- [A GraphQL type to allow retrieval of compliance violations](https://gitlab.com/gitlab-org/gitlab/-/issues/347325).
- [Consuming the merge request violations GraphQL type in the user interface](https://gitlab.com/gitlab-org/gitlab/-/issues/342897).

### View merge request violations

To view merge request violations:

1. On the top bar, select **Menu > Groups** and find your group.
1. On the left sidebar, select **Security & Compliance > Compliance report**.
