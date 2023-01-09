---
stage: Manage
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Jira development panel integration **(FREE)**

> [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/233149) from GitLab Premium to GitLab Free in 13.4.

With the Jira development panel integration, you can reference Jira issues in GitLab.
When configured, activity (such as pipeline, deployment, and feature flags) displays in the Jira issue's
[development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/).
From the development panel, you can open a detailed view and
[take various actions](#use-the-integration), including creating a new merge request from a branch:

![Branch, Commit and Pull Requests links on Jira issue](img/jira_dev_panel_jira_setup_3.png)

The information displayed in the Jira development panel depends on where you mention the Jira issue ID:

| Your mention of Jira issue ID in GitLab context   | Automated effect in Jira issue                                                                         |
|---------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| In a merge request title or description           | Link to the MR is displayed in the development panel.                                                      |
| In a branch name                                  | Link to the branch is displayed in the development panel.                                                  |
| In a commit message                               | Link to the commit is displayed in the development panel.                                                  |
| In a commit message with Jira [Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html) | Displays your custom comment or logged time spent and/or performs specified issue transition on merge. |

This integration connects all GitLab projects to projects in the Jira instance in either:

- A top-level GitLab group: Connects the projects in a group with no parent group,
  including the projects in its subgroups.
- A personal namespace: Connects the projects in that personal namespace to Jira.

## Use the integration

After the integration is [set up on GitLab and Jira](#configure-the-integration), you can:

- Refer to any Jira issue by its ID (in uppercase) in GitLab branch names,
  commit messages, and merge request titles.
- See the linked branches, commits, and merge requests in Jira issues.
- Create GitLab branches from Jira Cloud issues ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66032) in GitLab 14.2 for the GitLab for Jira app).

At this time, merge requests are called "pull requests" in Jira issues.
This name may change in a future Jira release.

Select the links to see your GitLab repository data.

![GitLab commits details on a Jira issue](img/jira_dev_panel_jira_setup_4.png)

![GitLab merge requests details on a Jira issue](img/jira_dev_panel_jira_setup_5.png)

### Use Jira Smart Commits

With Jira [Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html),
you can use GitLab to add Jira comments, log time spent on the issue, or apply any issue transition.

For more information about using Jira Smart Commits to track time against an issue, specify
an issue transition, or add a custom comment, read the Atlassian page
[Using Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html).

## Configure the integration

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of how to configure the Jira development panel integration, see
[Agile Management - GitLab Jira development panel integration](https://www.youtube.com/watch?v=VjVTOmMl85M).

To simplify administration, we recommend that a GitLab group maintainer or group owner
(or, if possible, instance administrator in the case of self-managed GitLab) set up the integration.

| Jira usage | GitLab.com customers need | GitLab self-managed customers need |
|------------|---------------------------|------------------------------------|
| [Atlassian cloud](https://www.atlassian.com/migration/assess/why-cloud) | The [GitLab.com for Jira Cloud app](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview) installed from the [Atlassian Marketplace](https://marketplace.atlassian.com). This method offers real-time sync between GitLab.com and Jira. For more information, see [GitLab.com for Jira Cloud app](connect-app.md). | The GitLab.com for Jira Cloud app [using a workaround](connect-app.md#install-the-gitlabcom-for-jira-cloud-app-for-self-managed-instances). When the `jira_connect_oauth_self_managed` feature flag is enabled, you can install the app from the [Atlassian Marketplace](https://marketplace.atlassian.com/). For more information, see [Connect the GitLab.com for Jira Cloud app for self-managed instances](connect-app.md#connect-the-gitlabcom-for-jira-cloud-app-for-self-managed-instances). |
| Your own server | The [Jira DVCS (distributed version control system) connector](dvcs.md). This syncs data hourly. | The [Jira DVCS (distributed version control system) connector](dvcs.md). This syncs data hourly. |

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
