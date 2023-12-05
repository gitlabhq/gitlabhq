---
stage: Govern
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Compliance center **(ULTIMATE ALL)**

> [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/122931) from Compliance report in GitLab 16.3.

See report and manage standards adherence, violations, and compliance frameworks for the group

## Standards adherence dashboard

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125875) GraphQL APIs in GitLab 16.2 [with a flag](../../../administration/feature_flags.md) named `compliance_adherence_report`. Disabled by default.
> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125444) standards adherence dashboard in GitLab 16.3 [with a flag](../../../administration/feature_flags.md) named `adherence_report_ui`. Disabled by default.
> - [Enabled](https://gitlab.com/gitlab-org/gitlab/-/issues/414495) in GitLab 16.5.
> - [Feature flag `compliance_adherence_report` and `adherence_report_ui`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/137398) removed in GitLab 16.7.

Standards adherence dashboard lists the adherence status of projects complying to GitLab standard.

When a project is added or an associated project or group setting is changed, an adherence scan is run on that project to update the standards adherence for that project. The date in the
**Last Scanned** column reflects any changes.

### View the standards adherence dashboard

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the standards adherence dashboard for a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.

### GitLab standard

GitLab standard consists of three rules:

- Prevent authors as approvers.
- Prevent committers as approvers.
- At least two approvals.

#### Prevent authors as approvers

To comply with GitLab standard, you must prevent users from approving their own merge requests. For more information,
see [Prevent approval by author](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author).

On self-managed GitLab, when instance-level setting for [prevent approval by author](../../../administration/merge_requests_approvals.md)
is updated, the adherence status for all the projects on the instance is not updated automatically.
To update the adherence status for these projects, the group-level or the project-level setting must be updated.

#### Prevent committers as approvers

To comply with GitLab standard, you must prevent users from approving merge requests where they've added commits. For
more information, see [Prevent approvals by users who add commits](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).

On self-managed GitLab, when instance-level setting for [prevent approvals by users who add commits](../../../administration/merge_requests_approvals.md)
is updated, the adherence status for all the projects on the instance is not updated automatically.
To update the adherence status for these projects, the group-level or the project-level setting must be updated.

#### At least two approvals

To comply with GitLab standard, you must have at least two users approve a merge request to get it merged. For more
information, see [Merge request approval rules](../../project/merge_requests/approvals/rules.md).

## Compliance violations report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/36524) in GitLab 12.8 as Compliance Dashboard.
> - Compliance violation drawer [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/299357) in GitLab 14.1.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/issues/299360) to compliance report in GitLab 14.2.
> - [Replaced](https://gitlab.com/groups/gitlab-org/-/epics/5237) by merge request violations in GitLab 14.6 [with a flag](../../../administration/feature_flags.md) named `compliance_violations_report`. Disabled by default.
> - GraphQL API [introduced](https://gitlab.com/groups/gitlab-org/-/epics/7222) in GitLab 14.9.
> - [Generally available](https://gitlab.com/groups/gitlab-org/-/epics/5237) in GitLab 14.10. [Feature flag `compliance_violations_report`](https://gitlab.com/gitlab-org/gitlab/-/issues/346266) removed.
> - [Renamed](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112111) to compliance violations report in GitLab 15.9.
> - Ability to create and edit compliance frameworks [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394950) in GitLab 16.0.

With compliance violations report, you can see a high-level view of merge request activity for all projects in the group.

When you select a row in the compliance report, a drawer appears that provides:

- The project name and [compliance framework label](../../project/working_with_projects.md#add-a-compliance-framework-to-a-project),
  if the project has one assigned.
- A link to the merge request that introduced the violation.
- The merge request's branch path in the format `[source] into [target]`.
- A list of users that committed changes to the merge request.
- A list of users that commented on the merge request.
- A list of users that approved the merge request.
- The user that merged the merge request.

### View the compliance violations report for a group

> Target branch search [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/358414) in GitLab 16.0.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the compliance violations report:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.

You can sort the compliance report on:

- Severity level.
- Type of violation.
- Merge request title.

You can filter the compliance violations report on:

- The project that the violation was found on.
- The date range of violation.
- The target branch of the violation.

Select a row to see details of the compliance violation.

#### Severity levels

Each compliance violation has one of the following severities.

<!-- vale gitlab.SubstitutionWarning = NO -->

| Icon                                          | Severity level |
|:----------------------------------------------|:---------------|
| **{severity-critical, 18, gl-fill-red-800}**  | Critical       |
| **{severity-high, 18, gl-fill-red-600}**      | High           |
| **{severity-medium, 18, gl-fill-orange-400}** | Medium         |
| **{severity-low, 18, gl-fill-orange-300}**    | Low            |
| **{severity-info, 18, gl-fill-blue-400}**     | Info           |

<!-- vale gitlab.SubstitutionWarning = YES -->

#### Violation types

From [GitLab 14.10](https://gitlab.com/groups/gitlab-org/-/epics/6870), these are the available compliance violations.

| Violation                         | Severity level | Category                                      | Description                                                                                                                                                                                                                                            |
|:----------------------------------|:---------------|:----------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Author approved merge request     | High           | [Separation of duties](#separation-of-duties) | Author of the merge request approved their own merge request. For more information, see [Prevent approval by author](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author).                                                   |
| Committers approved merge request | High           | [Separation of duties](#separation-of-duties) | Committers of the merge request approved the merge request they contributed to. For more information, see [Prevent approvals by users who add commits](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits). |
| Fewer than two approvals          | High           | [Separation of duties](#separation-of-duties) | Merge request was merged with fewer than two approvals. For more information, see [Merge request approval rules](../../project/merge_requests/approvals/rules.md).                                                                                     |

The following are unavailable compliance violations that are tracked in [epic 5237](https://gitlab.com/groups/gitlab-org/-/epics/5237).

<!-- vale gitlab.SubstitutionWarning = NO -->

| Violation                            | Severity level | Category                                                                               | Description                                                                                        |
|:-------------------------------------|:---------------|:---------------------------------------------------------------------------------------|:---------------------------------------------------------------------------------------------------|
| Pipeline failed                      | Medium         | [Pipeline results](../../../ci/pipelines/index.md)                                     | Merge requests pipeline failed and was merged.                                                     |
| Pipeline passed with warnings        | Info           | [Pipeline results](../../../ci/pipelines/index.md)                                     | Merge request pipeline passed with warnings and was merged.                                        |
| Code coverage down more than 10%     | High           | [Code coverage](../../../ci/testing/code_coverage.md#view-code-coverage-results-in-the-mr) | Code coverage report for the merge request indicates a reduction in coverage of more than 10%.     |
| Code coverage down between 5% to 10% | Medium         | [Code coverage](../../../ci/testing/code_coverage.md#view-code-coverage-results-in-the-mr) | Code coverage report for the merge request indicates a reduction in coverage of between 5% to 10%. |
| Code coverage down between 1% to 5%  | Low            | [Code coverage](../../../ci/testing/code_coverage.md#view-code-coverage-results-in-the-mr) | Code coverage report for the merge request indicates a reduction in coverage of between 1% to 5%.  |
| Code coverage down less than 1%      | Info           | [Code coverage](../../../ci/testing/code_coverage.md#view-code-coverage-results-in-the-mr) | Code coverage report for the merge request indicates a reduction in coverage of less than 1%.      |

<!-- vale gitlab.SubstitutionWarning = YES -->

##### Separation of duties

GitLab supports a separation of duties policy between users who create and approve merge requests. Our criteria for the
separation of duties is:

- [A merge request author is **not** allowed to approve their merge request](../../project/merge_requests/approvals/settings.md#prevent-approval-by-author).
- [A merge request committer is **not** allowed to approve a merge request they have added commits to](../../project/merge_requests/approvals/settings.md#prevent-approvals-by-users-who-add-commits).
- [The minimum number of approvals required to merge a merge request is **at least** two](../../project/merge_requests/approvals/rules.md).

### Export a report of merge request compliance violations on projects in a group

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/356791) in GitLab 16.4 [with a flag](../../../administration/feature_flags.md) named `compliance_violation_csv_export`. Disabled by default.
> - [Enabled on GitLab.com and self-managed](https://gitlab.com/gitlab-org/gitlab/-/issues/424447) in GitLab 16.5.

FLAG:
On self-managed GitLab, by default this feature is available. To hide the feature, an administrator can [disable the feature flag](../../../administration/feature_flags.md) named
`compliance_violation_csv_export`. On GitLab.com, this feature is available.

Export a report of merge request compliance violations on merge requests belonging to projects in a group. Reports:

- Do not use filters on the violations report.
- Are truncated at 15 MB so the email attachment is not too large.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export a report of merge request compliance violations for projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export violations report**.

A report is compiled and delivered to your email inbox as an attachment.

### Chain of Custody report

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

#### Generate Chain of Custody report

To generate the Chain of Custody report:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export chain of custody report**.

Depending on your version of GitLab, the Chain of Custody report is either sent through email or available for download.

#### Generate commit-specific Chain of Custody report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/267629) in GitLab 13.6.
> - Support for including all commits instead of only merge commits [added](https://gitlab.com/gitlab-org/gitlab/-/issues/393446) in GitLab 15.10.

You can generate a commit-specific Chain of Custody report for a given commit SHA. This report provides only the
details for the provided commit SHA.

To generate a commit-specific Chain of Custody report:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export custody report of a specific commit**.
1. Enter the commit SHA, and then select **Export custody report**.

Depending on your version of GitLab, the Chain of Custody report is either sent through email or available for download.

Alternatively, use a direct link: `https://gitlab.com/groups/<group-name>/-/security/merge_commit_reports.csv?commit_sha={optional_commit_sha}`,
passing in an optional value to the `commit_sha` query parameter.

## Compliance projects report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387910) in GitLab 15.10.
> - [Renamed from **compliance frameworks report**](https://gitlab.com/gitlab-org/gitlab/-/issues/422963) in GitLab 16.5.

With compliance projects report, you can see the compliance frameworks that are applied to projects in a group. Each row of the report shows:

- Project name.
- Project path.
- Compliance framework label if the project has one assigned.

The default framework for the group has a **default** badge.

### View the compliance projects report for a group

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the compliance projects report:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.

### Apply a compliance framework to projects in a group

> - Adding compliance frameworks using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383209) in GitLab 15.11.
> - Adding compliance frameworks without using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394795) in GitLab 16.0.

You can apply a compliance framework to projects in a group.

Prerequisites:

- You must have the Owner role for the group.

To apply a compliance framework to one project in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Next to the project you want to add the compliance framework to, select **{plus}** **Add framework**.
1. Select an existing compliance framework or create a new one.

To apply a compliance framework to multiple projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Select multiple projects.
1. From the **Choose one bulk action** dropdown list, select **Apply framework to selected projects**.
1. Select framework to apply.
1. Select **Apply**.

### Remove a compliance framework from projects in a group

> - Removing compliance frameworks using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/383209) in GitLab 15.11.
> - Removing compliance frameworks without using bulk actions [introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/394795) in GitLab 16.0.

You can remove a compliance framework from projects in a group.

Prerequisites:

- You must have the Owner role for the group.

To remove a compliance framework from one project in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Next to the compliance framework to remove from the project, select **{close}** on the framework label.

To remove a compliance framework from multiple projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. Select multiple projects.
1. From the **Choose one bulk action** dropdown list, select **Remove framework from selected projects**.
1. Select **Remove**.

### Export a report of compliance frameworks on projects in a group

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387912) in GitLab 16.0.

Export a report of compliance frameworks that are applied to projects in a group. Reports:

- Do not use filters on the framework report.
- Are truncated at 15 MB so the email attachment too large.

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To export a report of compliance frameworks on projects in a group:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export list of project frameworks**.

A report is compiled and delivered to your email inbox as an attachment.

#### Filter the compliance projects report

> [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/387911) in GitLab 15.11.

To filter the list of compliance frameworks:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. On the page, select the **Projects** tab.
1. In the search field:
   1. Select the attribute you want to filter by.
   1. Select an operator.
   1. Select from the list of options or enter text for the search.
1. Select **Search** (**{search}**).

Repeat this process to filter by multiple attributes.

## Compliance frameworks report

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/422973) in GitLab 16.5 [with a flag](../../../administration/feature_flags.md) named `compliance_framework_report_ui`. Disabled by default.
> - In GitLab 16.4 and earlier, **Compliance frameworks report** referred to what is now called **Compliance projects report**. The formally-named **Compliance frameworks report** was [renamed to **Compliance projects report**](https://gitlab.com/gitlab-org/gitlab/-/issues/422963) in GitLab 16.5.

FLAG:
On self-managed GitLab, by default this feature is not available. To make it available, ask an administrator to [enable the feature flag](../../../administration/feature_flags.md) named
`compliance_framework_report_ui`. On GitLab.com, this feature is not available. The feature is not ready for production use.

With compliance frameworks report, you can see all the compliance frameworks in a group. Each row of the report shows:

- Framework name.
- Associated projects.

The default framework for the group has a **default** badge.

### View the compliance frameworks report for a group

Prerequisites:

- You must be an administrator or have the Owner role for the group.

To view the compliance projects report:

1. On the left sidebar, select **Search or go to** and find your group.
1. On the left sidebar, select **Secure > Compliance center**.
1. On the page, select the **Frameworks** tab.
