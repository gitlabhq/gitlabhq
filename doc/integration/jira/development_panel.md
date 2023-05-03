---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira development panel **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/233149) from GitLab Premium to GitLab Free in 13.4.

You can use the Jira development panel to view GitLab activity for a Jira issue directly in Jira.
To set up the Jira development panel:

- **For Jira Cloud**, use the [GitLab for Jira Cloud app](connect-app.md) developed by GitLab.
- **For Jira Data Center or Jira Server**, use the [Jira DVCS connector](dvcs/index.md) developed by Atlassian.

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Jira development panel integration](https://www.youtube.com/watch?v=VjVTOmMl85M).

## Feature availability

This table shows the features available with the Jira DVCS connector and the GitLab for Jira Cloud app:

| Feature             | Jira DVCS connector    | GitLab for Jira Cloud app |
|---------------------|------------------------|---------------------------|
| Smart Commits       | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync merge requests | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync branches       | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync commits        | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync existing data  | **{check-circle}** Yes | **{check-circle}** Yes |
| Sync builds         | **{dotted-circle}** No | **{check-circle}** Yes |
| Sync deployments    | **{dotted-circle}** No | **{check-circle}** Yes |
| Sync feature flags  | **{dotted-circle}** No | **{check-circle}** Yes |
| Sync interval       | Up to 60 minutes       | Real time              |
| Create branches     | **{dotted-circle}** No | **{check-circle}** Yes (GitLab SaaS only) |
| Create merge request from branch | **{check-circle}** Yes | **{check-circle}** Yes |
| Create branch from Jira issue | **{dotted-circle}** No | **{check-circle}** Yes ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66032) in GitLab 14.2) |

## Connected projects in GitLab

The Jira development panel connects a Jira instance with all its projects to the following:

- **For the [GitLab for Jira Cloud app](connect-app.md)**, linked GitLab groups or subgroups and their projects
- **For the [Jira DVCS connector](dvcs/index.md)**, linked GitLab groups, subgroups, or personal namespaces and their projects

## Information displayed in the development panel

You can [view GitLab activity for a Jira issue](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/) in the Jira development panel by referring to the Jira issue by ID in GitLab.

The information displayed in the development panel depends on where you mention the Jira issue ID in GitLab.

| GitLab: where you mention the Jira issue ID    | Jira development panel: what information is displayed |
|------------------------------------------------|-------------------------------------------------------|
| Merge request title or description             | Link to the merge request<br>Link to the branch ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354373) in GitLab 15.11) |
| Branch name                                    | Link to the branch                                    |
| Commit message                                 | Link to the commit                                    |
| [Jira Smart Commit](#jira-smart-commits)       | Custom comment, logged time, or workflow transition   |

## Jira Smart Commits

Prerequisites:

- You must have GitLab and Jira user accounts with the same email address or username.
- The commands must be in the first line of the commit message.
- The commit message must not span more than one line.

Jira Smart Commits are special commands to process a Jira issue. With these commands, you can use GitLab to:

- Add a custom comment to a Jira issue.
- Log time against a Jira issue.
- Transition a Jira issue to any status defined in the project workflow.

### Smart Commit syntax

Smart Commits must follow this syntax:

```plaintext
<ISSUE_KEY> <ignored text> #<command> <optional command parameters>
```

You can execute one or more commands in a single commit.

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
