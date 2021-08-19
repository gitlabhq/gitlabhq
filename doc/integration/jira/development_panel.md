---
stage: Ecosystem
group: Integrations
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Jira Development panel integration **(FREE)**

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/233149) to GitLab Free in 13.4.

With the Jira Development panel integration, you can reference Jira issues in GitLab.
When configured, activity (such as pipeline, deployment, and feature flags) displays in the Jira issue's
[Development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/).
From the Development panel, you can open a detailed view and
[take various actions](#use-the-integration), including creating a new merge request from a branch:

![Branch, Commit and Pull Requests links on Jira issue](img/jira_dev_panel_jira_setup_3.png)

The information displayed in the Jira Development panel depends on where you mention the Jira issue ID:

| Your mention of Jira issue ID in GitLab context   | Automated effect in Jira issue                                                                         |
|---------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| In a merge request                                | Link to the MR is displayed in Development panel.                                                      |
| In a branch name                                  | Link to the branch is displayed in Development panel.                                                  |
| In a commit message                               | Link to the commit is displayed in Development panel.                                                  |
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
- Create GitLab branches from Jira issues ([introduced](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/66032) in GitLab 14.2).

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
For an overview of how to configure Jira Development panel integration, see
[Agile Management - GitLab Jira Development panel integration](https://www.youtube.com/watch?v=VjVTOmMl85M).

To simplify administration, we recommend that a GitLab group maintainer or group owner
(or instance administrator in the case of self-managed GitLab) set up the integration.

| Jira usage | GitLab.com customers need | GitLab self-managed customers need |
|------------|---------------------------|------------------------------------|
| [Atlassian cloud](https://www.atlassian.com/cloud) | The [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview) application installed from the [Atlassian Marketplace](https://marketplace.atlassian.com). This offers real-time sync between GitLab and Jira. For more information, see the documentation for the [GitLab.com for Jira Cloud app](connect-app.md). | The [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview), using a workaround process. See the documentation for [installing the GitLab Jira Cloud application for self-managed instances](connect-app.md#install-the-gitlabcom-for-jira-cloud-app-for-self-managed-instances) for more information. |
| Your own server | The [Jira DVCS (distributed version control system) connector](dvcs.md). This syncs data hourly. | The [Jira DVCS Connector](dvcs.md). |

Each GitLab project can be configured to connect to an entire Jira instance. That means after
configuration, one GitLab project can interact with all Jira projects in that instance. For:

- The [view Jira issues](issues.md#view-jira-issues) feature **(PREMIUM)**, you must associate a GitLab project with a
  specific Jira project.
- Other features, you do not have to explicitly associate a GitLab project with any single Jira
  project.

If you have a single Jira instance, you can pre-fill the settings. For more information, read the
documentation for [central administration of project integrations](../../user/admin_area/settings/project_integration_management.md).

## Limitations

This integration is not supported on GitLab instances under a
[relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab).
For example, `http://example.com/gitlab`.

## Related topics

- [Using Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html) in Jira

## Troubleshooting

### Cookies for Oracle's Access Manager

To support Oracle's Access Manager, GitLab sends additional cookies
to enable Basic Auth. The cookie being added to each request is `OBBasicAuth` with
a value of `fromDialog`.
