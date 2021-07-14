---
type: reference, howto
stage: Manage
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# Compliance Dashboard **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36524) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 12.8.

The Compliance Dashboard gives you the ability to see a group's merge request activity
by providing a high-level view for all projects in the group. For example, code approved
for merging into production.

## Overview

To access the Compliance Dashboard for a group, navigate to **{shield}** **Security & Compliance > Compliance** on the group's menu.

![Compliance Dashboard](img/compliance_dashboard_v13_11.png)

NOTE:
The Compliance Dashboard shows only the latest MR on each project.

## Merge request drawer

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299357) in GitLab 14.1.

When you click on a row, a drawer is shown that provides further details about the merge
request:

- Project name and [compliance framework label](../../project/settings/index.md#compliance-frameworks),
  if the project has one assigned.
- Link to the merge request.
- The merge request's branch path in the format `[source] into [target]`.
- A list of users that committed changes to the merge request.
- A list of users that commented on the merge request.
- A list of users that approved the merge request.
- The user that merged the merge request.

## Use cases

This feature is for people who care about the compliance status of projects within their group.

You can use the dashboard to:

- Get an overview of the latest merge request for each project.
- See if merge requests were approved and by whom.
- See merge request authors.
- See the latest [CI Pipeline](../../../ci/pipelines/index.md) result for each merge request.

## Permissions

- On [GitLab Ultimate](https://about.gitlab.com/pricing/) tier.
- By **Administrators** and **Group Owners**.

## Approval status and separation of duties

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/217939) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.3.

We support a separation of duties policy between users who create and approve merge requests.
The approval status column can help you identify violations of this policy.
Our criteria for the separation of duties is as follows:

- [A merge request author is **not** allowed to approve their merge request](../../project/merge_requests/approvals/settings.md#prevent-authors-from-approving-their-own-work)
- [A merge request committer is **not** allowed to approve a merge request they have added commits to](../../project/merge_requests/approvals/settings.md#prevent-committers-from-approving-their-own-work)
- [The minimum number of approvals required to merge a merge request is **at least** two](../../project/merge_requests/approvals/rules.md)

The "Approval status" column shows you, at a glance, whether a merge request is complying with the above.
This column has four states:

| State | Description |
|:------|:------------|
| Empty | The merge request approval status is unknown |
| ![Failed](img/failed_icon_v13_3.png) | The merge request **does not** comply with any of the above criteria |
| ![Warning](img/warning_icon_v13_3.png) | The merge request complies with **some** of the above criteria |
| ![Success](img/success_icon_v13_3.png) | The merge request complies with **all** of the above criteria |

If you do not see the success icon in your Compliance dashboard; please review the above criteria for the merge requests
project to make sure it complies with the separation of duties described above.

## Chain of Custody report **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/213364) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.3.

The Chain of Custody report allows customers to export a list of merge commits within the group.
The data provides a comprehensive view with respect to merge commits. It includes the merge commit SHA,
merge request author, merge request ID, merge user, pipeline ID, group name, project name, and merge request approvers.
Depending on the merge strategy, the merge commit SHA can either be a merge commit, squash commit or a diff head commit.

To download the Chain of Custody report, navigate to **{shield}** **Security & Compliance > Compliance** on the group's menu and click **List of all merge commits**

### Commit-specific Chain of Custody Report **(ULTIMATE)**

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267629) in [GitLab Ultimate](https://about.gitlab.com/pricing/) 13.6.

You can generate a commit-specific Chain of Custody report for a given commit SHA. To do so, select
the dropdown next to the **List of all merge commits** button at the top of the Compliance Dashboard.

NOTE:
The Chain of Custody report download is a CSV file, with a maximum size of 15 MB.
The remaining records are truncated when this limit is reached.
