---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira development panel

DETAILS:
**Tier:** Free, Premium, Ultimate
**Offering:** GitLab.com, Self-managed, GitLab Dedicated

You can use the Jira development panel to view GitLab activity for a Jira issue directly in Jira.
To set up the Jira development panel:

- **For Jira Cloud**, use the [GitLab for Jira Cloud app](connect-app.md) developed and maintained by GitLab.
- **For Jira Data Center or Jira Server**, use the [Jira DVCS connector](dvcs/index.md) developed and maintained by Atlassian.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Jira development panel integration](https://www.youtube.com/watch?v=VjVTOmMl85M).

## Feature availability

This table shows the features available with the Jira DVCS connector and the GitLab for Jira Cloud app:

| Feature                              | Jira DVCS connector    | GitLab for Jira Cloud app |
|--------------------------------------|------------------------|---------------------------|
| Smart Commits                        | **{check-circle}** Yes | **{check-circle}** Yes    |
| Sync merge requests                  | **{check-circle}** Yes | **{check-circle}** Yes    |
| Sync branches                        | **{check-circle}** Yes | **{check-circle}** Yes    |
| Sync commits                         | **{check-circle}** Yes | **{check-circle}** Yes    |
| Sync existing data                   | **{check-circle}** Yes | **{check-circle}** Yes (see [GitLab data synced to Jira](connect-app.md#gitlab-data-synced-to-jira)) |
| Sync builds                          | **{dotted-circle}** No | **{check-circle}** Yes    |
| Sync deployments                     | **{dotted-circle}** No | **{check-circle}** Yes    |
| Sync feature flags                   | **{dotted-circle}** No | **{check-circle}** Yes    |
| Sync interval                        | Up to 60 minutes       | Real time                 |
| Create branches                      | **{dotted-circle}** No | **{check-circle}** Yes (GitLab.com only) |
| Create a merge request from a branch | **{check-circle}** Yes | **{check-circle}** Yes    |
| Create a branch from a Jira issue    | **{dotted-circle}** No | **{check-circle}** Yes ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66032) in GitLab 14.2) |

## Connected projects in GitLab

The Jira development panel connects a Jira instance with all its projects to the following:

- **For the [GitLab for Jira Cloud app](connect-app.md)**, linked GitLab groups or subgroups and their projects
- **For the [Jira DVCS connector](dvcs/index.md)**, linked GitLab groups, subgroups, or personal namespaces and their projects

## Information displayed in the development panel

You can [view GitLab activity for a Jira issue](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)
in the Jira development panel by referring to the Jira issue by ID in GitLab. The information displayed in the development panel
depends on where you mention the Jira issue ID in GitLab.

For the [GitLab for Jira Cloud app](connect-app.md), the following information is displayed.

| GitLab: where you mention the Jira issue ID | Jira development panel: what information is displayed |
|---------------------------------------------|-------------------------------------------------------|
| Merge request title or description          | Link to the merge request<br>Link to the deployment<br>Link to the pipeline through the merge request title<br>Link to the pipeline through the merge request description ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/390888) in GitLab 15.10)<br>Link to the branch ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354373) in GitLab 15.11)<br>Reviewer information and approval status ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/364273) in GitLab 16.5) |
| Branch name                                 | Link to the branch<br>Link to the deployment          |
| Commit message                              | Link to the commit<br>Link to the deployment from up to 5,000 commits after the last successful deployment to the environment <sup>1</sup> <sup>2</sup> |
| [Jira Smart Commit](#jira-smart-commits)    | Custom comment, logged time, or workflow transition   |

**Footnotes:**

1. [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/300031) in GitLab 16.2 [with a flag](../../administration/feature_flags.md) named `jira_deployment_issue_keys`. Enabled by default.
1. [Generally available](https://gitlab.com/gitlab-org/gitlab/-/issues/415025) in GitLab 16.3. Feature flag `jira_deployment_issue_keys` removed.

## Jira Smart Commits

Prerequisites:

- You must have GitLab and Jira user accounts with the same email address or username.
- The commands must be in the first line of the commit message.
- The commit message must not span more than one line.

Jira Smart Commits are special commands to process a Jira issue. With these commands, you can use GitLab to:

- Add a custom comment to a Jira issue.
- Log time against a Jira issue.
- Transition a Jira issue to any status defined in the project workflow.

Smart Commits must follow this syntax:

```plaintext
<ISSUE_KEY> <ignored text> #<command> <optional command parameters>
```

You can execute one or more commands in a single commit.

### Smart Commit syntax

| Commands                                        | Syntax                                                       |
|-------------------------------------------------|--------------------------------------------------------------|
| Add a comment                                   | `KEY-123 #comment Bug is fixed`                              |
| Log time                                        | `KEY-123 #time 2w 4d 10h 52m Tracking work time`             |
| Close an issue                                  | `KEY-123 #close Closing issue`                               |
| Log time and close an issue                     | `KEY-123 #time 2d 5h #close`                                 |
| Add a comment and transition to **In-progress** | `KEY-123 #comment Started working on the issue #in-progress` |

For more information about how Smart Commits work and what commands are available to use, see:

- [Process issues with Smart Commits](https://support.atlassian.com/jira-software-cloud/docs/process-issues-with-smart-commits/)
- [Using Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html)

## Related topics

- [Troubleshoot the development panel in Jira Server](https://confluence.atlassian.com/jirakb/troubleshoot-the-development-panel-in-jira-server-574685212.html)
