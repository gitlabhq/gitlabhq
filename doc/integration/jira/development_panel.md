---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Jira development panel **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/233149) from GitLab Premium to GitLab Free in 13.4.

You can view GitLab activity from the Jira development panel.

When you are in GitLab, you refer to a Jira issue by ID. Then
[the activity](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)
for that issue is displayed in the Jira development panel.

In the Jira development panel, you can create a GitLab merge request from a branch.
You can also create a GitLab branch from a Jira Cloud issue
([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66032) in GitLab 14.2).

## Connected projects in GitLab

The Jira development panel connects to the Jira instance all GitLab projects in:

- A top-level group, including all projects in its subgroups.
- A personal namespace.

## Where the Jira ID displayed

The information displayed in the Jira development panel depends on where you mention the Jira issue ID in GitLab.

| GitLab: where you mention the Jira issue ID    | Jira development panel: what information is displayed |
|------------------------------------------------|-------------------------------------------------------|
| Merge request title or description             | Link to the merge request                             |
| Branch name                                    | Link to the branch                                    |
| Commit message                                 | Link to the commit                                    |
| [Jira Smart Commit](#jira-smart-commits)       | Custom comment, logged time, or workflow transition   |

## Jira Smart Commits

Jira Smart Commits are special commands to process a Jira issue. With these commands, you can use GitLab to:

- Add a custom comment to a Jira issue.
- Log time against a Jira issue.
- Transition a Jira issue to any status defined in the project workflow.

For more information, see [Using Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html)
in the Atlassian documentation.

## Configure the integration

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of how to configure the Jira development panel integration, see
[Agile Management - GitLab Jira development panel integration](https://www.youtube.com/watch?v=VjVTOmMl85M).

To simplify administration, we recommend that a GitLab group maintainer or group owner
(or, if possible, instance administrator in the case of self-managed GitLab) set up the integration.

| Jira usage | GitLab.com customers need | GitLab self-managed customers need |
|------------|---------------------------|------------------------------------|
| [Atlassian cloud](https://www.atlassian.com/migration/assess/why-cloud) | The [GitLab for Jira Cloud app](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview) from the [Atlassian Marketplace](https://marketplace.atlassian.com). This method offers real-time sync between GitLab.com and Jira. The method requires inbound connections for the setup and then pushes data to Jira through outbound connections. For more information, see [GitLab for Jira Cloud app](connect-app.md). | The GitLab for Jira Cloud app [installed manually](connect-app.md#install-the-gitlab-for-jira-cloud-app-manually). By default, you can install the app from the [Atlassian Marketplace](https://marketplace.atlassian.com/). The method requires inbound connections for the setup and then pushes data to Jira through outbound connections. For more information, see [Connect the GitLab for Jira Cloud app for self-managed instances](connect-app.md#connect-the-gitlab-for-jira-cloud-app-for-self-managed-instances). |
| Your own server | The [Jira DVCS connector](dvcs/index.md). This method syncs data every hour and works only with inbound connections. The method tries to set up webhooks in GitLab to implement real-time data sync, which does not work without outbound connections. | The [Jira DVCS connector](dvcs/index.md). This method syncs data every hour and works only with inbound connections. The method tries to set up webhooks in GitLab to implement real-time data sync, which does not work without outbound connections. |

Each GitLab project can be configured to connect to an entire Jira instance. That means after
configuration, one GitLab project can interact with all Jira projects in that instance. For:

- The [view Jira issues](issues.md#view-jira-issues) feature, you must associate a GitLab project with a
  specific Jira project.
- Other features, you do not have to explicitly associate a GitLab project with any single Jira
  project.

If you have a single Jira instance, you can pre-fill the settings. For more information, read the
documentation for [central administration of project integrations](../../user/admin_area/settings/project_integration_management.md).

## Limitations

- This integration is not supported on GitLab instances under a
[relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configure-a-relative-url-for-gitlab)
(for example, `http://example.com/gitlab`).
- [Creating a branch](https://gitlab.com/gitlab-org/gitlab/-/issues/2647) is only supported by the GitLab for Jira app and is not available within the DVCS integration. See [officially supported DVCS features](https://confluence.atlassian.com/adminjiraserver/integrating-with-development-tools-938846890.html) for more information.

## Troubleshoot the development panel

If you use Jira on your own server, go to the [Atlassian documentation](https://confluence.atlassian.com/jirakb/troubleshoot-the-development-panel-in-jira-server-574685212.html)
for general troubleshooting information.

### Cookies for Oracle's Access Manager

To support Oracle's Access Manager, GitLab sends additional cookies
to enable Basic Auth. The cookie being added to each request is `OBBasicAuth` with
a value of `fromDialog`.
