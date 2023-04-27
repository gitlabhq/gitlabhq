---
stage: Manage
group: Import and Integrate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira development panel **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/233149) from GitLab Premium to GitLab Free in 13.4.

The Jira development panel connects all GitLab projects in a group or personal namespace
where you can view GitLab activity.

When you're in GitLab, you can refer to a Jira issue by ID.
The [activity for that issue](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)
is displayed in the Jira development panel.

In the Jira development panel, you can create a GitLab merge request from a branch.
You can also create a GitLab branch from a Jira issue in the GitLab for Jira Cloud app
([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66032) in GitLab 14.2).

## Connected projects in GitLab

The Jira development panel connects to the entire Jira instance all GitLab projects in:

- A top-level group, including all projects in its subgroups.
- A personal namespace.

These GitLab projects can interact with all Jira projects in that instance.

## Information displayed in the panel

The information displayed in the Jira development panel depends on where you mention the Jira issue ID in GitLab.

| GitLab: where you mention the Jira issue ID    | Jira development panel: what information is displayed |
|------------------------------------------------|-------------------------------------------------------|
| Merge request title or description             | Link to the merge request<br>Link to the branch ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/354373) in GitLab 15.11) |
| Branch name                                    | Link to the branch                                    |
| Commit message                                 | Link to the commit                                    |
| [Jira Smart Commit](#jira-smart-commits)       | Custom comment, logged time, or workflow transition   |

## Jira Smart Commits

Jira Smart Commits are special commands to process a Jira issue. With these commands, you can use GitLab to:

- Add a custom comment to a Jira issue.
- Log time against a Jira issue.
- Transition a Jira issue to any status defined in the project workflow.

For more information, see the
[Atlassian documentation](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html).

## Configure the panel

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview, see [Jira development panel integration](https://www.youtube.com/watch?v=VjVTOmMl85M).

### For GitLab.com

Prerequisite:

- You must have at least the Maintainer role for the group.

To configure the Jira development panel on GitLab.com:

- **For [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud)**:
  - [From the Atlassian Marketplace, install the GitLab for Jira Cloud app](https://marketplace.atlassian.com/apps/1221011/gitlab-for-jira-cloud?hosting=cloud&tab=overview).
  - This method syncs data between GitLab.com and Jira in real time.
  - This method requires inbound connections for the setup and outbound connections to push data to Jira.
  - For more information, see [GitLab for Jira Cloud app](connect-app.md).
- **For Jira Server**:
  - Use the [Jira DVCS connector](dvcs/index.md).
  - This method syncs data every hour and works only with inbound connections.
  - This method attempts to set up webhooks in GitLab to sync data in real time, which requires outbound connections.

### For self-managed GitLab

Prerequisites:

- You must have administrator access to the instance.
- Your GitLab installation must not use a [relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-relative-url-for-gitlab)
  (for example, `https://example.com/gitlab`).

To configure the Jira development panel on self-managed GitLab:

- **For [Jira Cloud](https://www.atlassian.com/migration/assess/why-cloud)**:
  - [Install the GitLab for Jira Cloud app manually](connect-app.md#install-the-gitlab-for-jira-cloud-app-manually).
  - This method requires inbound connections for the setup and outbound connection to push data to Jira.
  - For more information, see [Connect the GitLab for Jira Cloud app for self-managed instances](connect-app.md#connect-the-gitlab-for-jira-cloud-app-for-self-managed-instances).
- **For Jira Server**:
  - Use the [Jira DVCS connector](dvcs/index.md).
  - This method syncs data every hour and works only with inbound connections.
  - This method attempts to set up webhooks in GitLab to sync data in real time, which requires outbound connections.

## Troubleshooting

To troubleshoot the Jira development panel on your own server, see the
[Atlassian documentation](https://confluence.atlassian.com/jirakb/troubleshoot-the-development-panel-in-jira-server-574685212.html).
