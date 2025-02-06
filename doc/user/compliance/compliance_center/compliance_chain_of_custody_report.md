---
stage: Software Supply Chain Security
group: Compliance
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Chain of Custody report
---

DETAILS:
**Tier:** Ultimate
**Offering:** GitLab.com, GitLab Self-Managed, GitLab Dedicated

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

## Generate Chain of Custody report

To generate the Chain of Custody report:

1. On the left sidebar, select **Search or go to** and find your group.
1. Select **Secure > Compliance center**.
1. In the top-right corner, select **Export**.
1. Select **Export chain of custody report**.

Depending on your version of GitLab, the Chain of Custody report is either sent through email or available for download.

## Generate commit-specific Chain of Custody report

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
