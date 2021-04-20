---
stage: Create
group: Ecosystem
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# GitLab Jira Development panel integration **(FREE)**

> - [Moved](https://gitlab.com/gitlab-org/gitlab/-/issues/233149) to GitLab Free in 13.4.

The Jira Development panel integration allows you to reference Jira issues in GitLab, displaying
activity in the [Development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/)
in the issue.

It complements the [GitLab Jira integration](../../user/project/integrations/jira.md). You may choose
to configure both integrations to take advantage of both sets of features. See a
[feature comparison](index.md#direct-feature-comparison).

## Features

| Your mention of Jira issue ID in GitLab context   | Automated effect in Jira issue                                                                         |
|---------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| In a merge request                                | Link to the MR is displayed in Development panel.                                                      |
| In a branch name                                  | Link to the branch is displayed in Development panel.                                                  |
| In a commit message                               | Link to the commit is displayed in Development panel.                                                  |
| In a commit message with Jira Smart Commit format | Displays your custom comment or logged time spent and/or performs specified issue transition on merge. |

With this integration, you can access related GitLab merge requests, branches, and commits directly from a Jira issue, reflecting your work in GitLab. From the Development panel, you can open a detailed view and take actions including creating a new merge request from a branch. For more information, see [Usage](#usage).

This integration connects all GitLab projects to projects in the Jira instance in either:

- A top-level group. A top-level GitLab group is one that does not have any parent group itself. All
  the projects of that top-level group, as well as projects of the top-level group's subgroups nesting
  down, are connected.
- A personal namespace, which then connects the projects in that personal namespace to Jira.

This differs from the [Jira integration](../../user/project/integrations/jira.md), where the mapping is between one GitLab project and the entire Jira instance.

Additional features provided by the Jira Development Panel integration include:

- In a Jira issue, display relevant GitLab information in the [development panel](https://support.atlassian.com/jira-software-cloud/docs/view-development-information-for-an-issue/), including related branches, commits, and merge requests.
- Use Jira [Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html) in GitLab to add Jira comments, log time spent on the issue, or apply any issue transition.
- Showing pipeline, deployment, and feature flags in Jira issues.

## Configuration

<i class="fa fa-youtube-play youtube" aria-hidden="true"></i>
For an overview of how to configure Jira Development panel integration, see [Agile Management - GitLab Jira Development panel integration](https://www.youtube.com/watch?v=VjVTOmMl85M&feature=youtu.be).

We recommend that a GitLab group maintainer or group owner, or instance administrator (in the case of
self-managed GitLab) set up the integration to simplify administration.

| If you use Jira on: | GitLab.com customers need: | GitLab self-managed customers need: |
|-|-|-|
| [Atlassian cloud](https://www.atlassian.com/cloud) | The [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview) application installed from the [Atlassian Marketplace](https://marketplace.atlassian.com). This offers real-time sync between GitLab and Jira. | The [GitLab.com for Jira Cloud](https://marketplace.atlassian.com/apps/1221011/gitlab-com-for-jira-cloud?hosting=cloud&tab=overview), using a workaround process. See the documentation for [installing the GitLab Jira Cloud application for self-managed instances](connect-app.md#install-the-gitlab-jira-cloud-application-for-self-managed-instances) for more information. |
| Your own server | The Jira DVCS (distributed version control system) connector. This syncs data hourly. | The [Jira DVCS Connector](dvcs.md). |

Each GitLab project can be configured to connect to an entire Jira instance. That means one GitLab
project can interact with _all_ Jira projects in that instance, once configured. For:

- The [view Jira issues](issues.md#view-jira-issues) feature, you must associate a GitLab project with a
  specific Jira project.
- Other features, you do not have to explicitly associate a GitLab project with any single Jira
  project.

If you have a single Jira instance, you can pre-fill the settings. For more information, read the
documentation for [central administration of project integrations](../../user/admin_area/settings/project_integration_management.md).

To enable the Jira service in GitLab, you must:

1. Configure the project in Jira.
1. Enter the correct values in GitLab.

### Configure GitLab

> **Notes:**
>
> - The supported Jira versions are `v6.x`, `v7.x`, and `v8.x`.
> - In order to support Oracle's Access Manager, GitLab sends additional cookies
>   to enable Basic Auth. The cookie being added to each request is `OBBasicAuth` with
>   a value of `fromDialog`.

To enable the Jira integration in a project:

1. Go to the project's [Integrations page](../../user/project/integrations/overview.md#accessing-integrations) and select the
   **Jira** service.

1. Select **Enable integration**.

1. Select **Trigger** actions.
   This determines whether a mention of a Jira issue in GitLab commits, merge requests, or both,
   should link the Jira issue back to that source commit/MR and transition the Jira issue, if
   indicated.

1. To include a comment on the Jira issue when the above reference is made in GitLab, select
   **Enable comments**.

1. To transition Jira issues when a [closing reference](../../user/project/issues/managing_issues.md#closing-issues-automatically) is made in GitLab,
   select **Enable Jira transitions**.

1. Enter the further details on the page as described in the following table.

   | Field | Description |
   | ----- | ----------- |
   | `Web URL` | The base URL to the Jira instance web interface which is being linked to this GitLab project. For example, `https://jira.example.com`. |
   | `Jira API URL` | The base URL to the Jira instance API. Web URL value is used if not set. For example, `https://jira-api.example.com`. Leave this field blank (or use the same value of `Web URL`) if using **Jira on Atlassian cloud**. |
   | `Username or Email` | Created in [configure Jira](dvcs.md#configure-jira-for-dvcs) step. Use `username` for **Jira Server** or `email` for **Jira on Atlassian cloud**. |
   | `Password/API token` | Created in [configure Jira](dvcs.md#configure-jira-for-dvcs) step. Use `password` for **Jira Server** or `API token` for **Jira on Atlassian cloud**. |

1. To enable users to view Jira issues inside the GitLab project, select **Enable Jira issues** and
   enter a Jira project key. **(PREMIUM)**

   You can only display issues from a single Jira project within a given GitLab project.

   WARNING:
   If you enable Jira issues with the setting above, all users that have access to this GitLab project
   are able to view all issues from the specified Jira project.

1. To enable creation of issues for vulnerabilities, select **Enable Jira issues creation from vulnerabilities**.

   1. Select the **Jira issue type**. If the dropdown is empty, select refresh (**{retry}**) and try again.

1. To verify the Jira connection is working, select **Test settings**.

1. Select **Save changes**.

Your GitLab project can now interact with all Jira projects in your instance and the project now
displays a Jira link that opens the Jira project.

## Usage

After the integration is set up on GitLab and Jira, you can:

- Refer to any Jira issue by its ID in GitLab branch names, commit messages, and merge request
  titles.
- See the linked branches, commits, and merge requests in Jira issues (merge requests are
  called "pull requests" in Jira issues).

Jira issue IDs must be formatted in uppercase for the integration to work.

![Branch, Commit and Pull Requests links on Jira issue](img/jira_dev_panel_jira_setup_3.png)

Click the links to see your GitLab repository data.

![GitLab commits details on a Jira issue](img/jira_dev_panel_jira_setup_4.png)

![GitLab merge requests details on a Jira issue](img/jira_dev_panel_jira_setup_5.png)

For more information on using Jira Smart Commits to track time against an issue, specify an issue transition, or add a custom comment, see the Atlassian page [Using Smart Commits](https://confluence.atlassian.com/fisheye/using-smart-commits-960155400.html).

## Limitations

This integration is not supported on GitLab instances under a
[relative URL](https://docs.gitlab.com/omnibus/settings/configuration.html#configuring-a-relative-url-for-gitlab).
For example, `http://example.com/gitlab`.
