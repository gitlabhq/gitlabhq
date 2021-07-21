---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
type: reference
---

# GitLab Admin Area **(FREE SELF)**

The Admin Area provides a web UI to manage and configure some features of GitLab
self-managed instances. If you are an Admin user, you can access the Admin Area
by visiting `/admin` on your self-managed instance. You can also access it through
the UI:

- GitLab versions 14.0 and later: on the top bar, select **Menu >** **{admin}** **Admin**.
- GitLab versions 13.12 and earlier: on the top bar, select the Admin Area icon (**{admin}**).

NOTE:
Only admin users can access the Admin Area.

## Admin Area sections

The Admin Area is made up of the following sections:

| Section                                        | Description |
|:-----------------------------------------------|:------------|
| **{overview}** [Overview](#overview-section)   | View your GitLab [Dashboard](#admin-dashboard), and administer [projects](#administering-projects), [users](#administering-users), [groups](#administering-groups), [jobs](#administering-jobs), [runners](#administering-runners), and [Gitaly servers](#administering-gitaly-servers). |
| **{monitor}** Monitoring                       | View GitLab [system information](#system-information), and information on [background jobs](#background-jobs), [logs](#logs), [health checks](monitoring/health_check.md), [requests profiles](#requests-profiles), and [audit events](#audit-events). |
| **{messages}** Messages                        | Send and manage [broadcast messages](broadcast_messages.md) for your users. |
| **{hook}** System Hooks                        | Configure [system hooks](../../system_hooks/system_hooks.md) for many events. |
| **{applications}** Applications                | Create system [OAuth applications](../../integration/oauth_provider.md) for integrations with other services. |
| **{slight-frown}** Abuse Reports               | Manage [abuse reports](review_abuse_reports.md) submitted by your users. |
| **{license}** License                          | Upload, display, and remove [licenses](license.md). |
| **{cloud-gear}** Kubernetes                    | Create and manage instance-level [Kubernetes clusters](../instance/clusters/index.md). |
| **{push-rules}** Push rules | Configure pre-defined Git [push rules](../../push_rules/push_rules.md) for projects. Also, configure [merge requests approvers rules](merge_requests_approvals.md). |
| **{location-dot}** Geo                         | Configure and maintain [Geo nodes](geo_nodes.md). |
| **{key}** Deploy keys                          | Create instance-wide [SSH deploy keys](../project/deploy_keys/index.md). |
| **{lock}** Credentials                         | View [credentials](credentials_inventory.md) that can be used to access your instance. |
| **{template}** Integrations                    | Manage [instance-level default settings](settings/project_integration_management.md) for a project integration. |
| **{labels}** Labels                            | Create and maintain [labels](labels.md) for your GitLab instance. |
| **{appearance}** Appearance                    | Customize [GitLab appearance](appearance.md). |
| **{settings}** Settings                        | Modify the [settings](settings/index.md) for your GitLab instance. |

## Admin Dashboard

The Dashboard provides statistics and system information about the GitLab instance.

To access the Dashboard, either:

- On the top bar, select **Menu >** **{admin}** **Admin**.
- Visit `/admin` on your self-managed instance.

The Dashboard is the default view of the Admin Area, and is made up of the following sections:

| Section    | Description |
|:-----------|:------------|
| Projects   | The total number of projects, up to 10 of the latest projects, and the option of creating a new project. |
| Users      | The total number of users, up to 10 of the latest users, the option of creating a new user, and a link to [**Users statistics**](#users-statistics). |
| Groups     | The total number of groups, up to 10 of the latest groups, and the option of creating a new group. |
| Statistics | Totals of all elements of the GitLab instance. |
| Features   | All features available on the GitLab instance. Enabled features are marked with a green circle icon, and disabled features are marked with a power icon. |
| Components | The major components of GitLab and the version number of each. A link to the Gitaly Servers is also included. |

## Overview section

The following topics document the **Overview** section of the Admin Area.

### Administering Projects

You can administer all projects in the GitLab instance from the Admin Area's Projects page.

To access the Projects page:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Overview > Projects**.
1. Select the **All**, **Private**, **Internal**, or **Public** tab to list only
   projects of that criteria.

By default, all projects are listed, in reverse order of when they were last updated. For each
project, the following information is listed:

- Name.
- Namespace.
- Description.
- Size, updated every 15 minutes at most.

Projects can be edited or deleted.

The list of projects can be sorted by:

- Name.
- Last created.
- Oldest created.
- Last updated.
- Oldest updated.
- Owner.

A user can choose to hide or show archived projects in the list.

In the **Filter by name** field, type the project name you want to find, and GitLab filters
them as you type.

Select from the **Namespace** dropdown to filter only projects in that namespace.

You can combine the filter options. For example, to list only public projects with `score` in their name:

1. Click the **Public** tab.
1. Enter `score` in the **Filter by name...** input box.

### Administering Users

You can administer all users in the GitLab instance from the Admin Area's Users page:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Overview > Users**.

To list users matching a specific criteria, click on one of the following tabs on the **Users** page:

- **Active**
- **Admins**
- **2FA Enabled**
- **2FA Disabled**
- **External**
- **[Blocked](moderate_users.md#block-a-user)**
- **[Deactivated](moderate_users.md#deactivate-a-user)**
- **Without projects**

For each user, the following are listed:

1. Username
1. Email address
1. Project membership count
1. Group membership count ([introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/276215) in GitLab 13.12)
1. Date of account creation
1. Date of last activity

To edit a user, click the **Edit** button in that user's
row. To delete the user, or delete the user and their contributions, click the cog dropdown in
that user's row, and select the desired option.

To change the sort order:

1. Click the sort dropdown.
1. Select the desired order.

By default the sort dropdown shows **Name**.

To search for users, enter your criteria in the search field. The user search is case
insensitive, and applies partial matching to name and username. To search for an email address,
you must provide the complete email address.

#### User impersonation

An administrator can "impersonate" any other user, including other administrator users.
This allows the administrator to "see what the user sees," and take actions on behalf of the user.
You can impersonate a user in the following ways:

- Through the UI:
  1. On the top bar, select **Menu >** **{admin}** **Admin**.
  1. In the left sidebar, select **Overview > Users**.
  1. From the list of users, select a user.
  1. Select **Impersonate**.
- With the API, using [impersonation tokens](../../api/index.md#impersonation-tokens).

All impersonation activities are [captured with audit events](../../administration/audit_events.md#impersonation-data).

![user impersonation button](img/impersonate_user_button_v13_8.png)

#### User Permission Export **(PREMIUM SELF)**

> - [Introduced](https://gitlab.com/gitlab-org/gitlab/-/issues/1772) in GitLab 13.8.
> - [Feature flag removed](https://gitlab.com/gitlab-org/gitlab/-/issues/292436) in GitLab 13.9.

An administrator can export user permissions for all users in the GitLab instance from the Admin Area's Users page.
The export lists direct membership the users have in groups and projects.

The following data is included in the export:

- Username
- Email
- Type
- Path
- Access level ([Project](../permissions.md#project-members-permissions) and [Group](../permissions.md#group-members-permissions))

![user permission export button](img/export_permissions_v13_11.png)

#### Users statistics

The **Users statistics** page provides an overview of user accounts by role. These statistics are
calculated daily, so user changes made since the last update are not reflected.

The following totals are also included:

- Billable users
- Blocked users
- Total users

GitLab billing is based on the number of [**Billable users**](../../subscriptions/self_managed/index.md#billable-users).

### User cohorts

The [Cohorts](user_cohorts.md) tab displays the monthly cohorts of new users and their activities over time.

### Administering Groups

You can administer all groups in the GitLab instance from the Admin Area's Groups page.

To access the Groups page:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Overview > Groups**.

For each group, the page displays their name, description, size, number of projects in the group,
number of members, and whether the group is private, internal, or public. To edit a group, click
the **Edit** button in that group's row. To delete the group, click the **Delete** button in
that group's row.

To change the sort order, click the sort dropdown and select the desired order. The default
sort order is by **Last created**.

To search for groups by name, enter your criteria in the search field. The group search is case
insensitive, and applies partial matching.

To [Create a new group](../group/index.md#create-a-group) click **New group**.

### Administering Jobs

You can administer all jobs in the GitLab instance from the Admin Area's Jobs page.

To access the Jobs page:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Overview > Jobs**. All jobs are listed, in descending order of job ID.
1. Click the **All** tab to list all jobs. Click the **Pending**, **Running**, or **Finished**
   tab to list only jobs of that status.

For each job, the following details are listed:

| Field    | Description |
|----------|-------------|
| Status   | Job status, either **passed**, **skipped**, or **failed**.              |
| Job      | Includes links to the job, branch, and the commit that started the job. |
| Pipeline | Includes a link to the specific pipeline.                               |
| Project  | Name of the project, and organization, to which the job belongs.        |
| Runner   | Name of the CI runner assigned to execute the job.                      |
| Stage    | Stage that the job is declared in a `.gitlab-ci.yml` file.              |
| Name     | Name of the job specified in a `.gitlab-ci.yml` file.                   |
| Timing   | Duration of the job, and how long ago the job completed.                |
| Coverage | Percentage of tests coverage.                                           |

### Administering runners

You can administer all runners in the GitLab instance from the Admin Area's **Runners** page. See
[GitLab Runner](https://docs.gitlab.com/runner/) for more information.

To access the **Runners** page:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Overview > Runners**.

The **Runners** page features:

- A description of runners and their possible states.
- Instructions on installing a runner.
- A list of all registered runners.

Runners are listed in descending order by the date they were created, by default. You can change
the sort order to *Last Contacted* from the dropdown beside the search field.

To search runners' descriptions:

1. In the **Search or filter results...** field, type the description of the runner you want to
   find.
1. Press Enter.

You can also filter runners by status, type, and tag. To filter:

1. Click in the **Search or filter results...** field.
1. Select **Status**, **Type**, or **Tags**.
1. Select or enter your search criteria.

![Attributes of a runner, with the **Search or filter results...** field active](img/index_runners_search_or_filter_v14_1.png)

For each runner, the following attributes are listed:

| Attribute    | Description |
|--------------|-------------|
| Type/State   | One or more of the following states: shared, group, specific, locked, or paused |
| Runner token | Partial token used to identify the runner, and which the runner uses to communicate with the GitLab instance |
| Runner ID    | Numerical ID of the runner |
| Description  | Description given to the runner |
| Version      | GitLab Runner version |
| IP address   | IP address of the host on which the runner is registered |
| Projects     | Number of projects to which the runner is assigned |
| Jobs         | Total of jobs run by the runner |
| Tags         | Tags associated with the runner |
| Last contact | Timestamp indicating when the runner last contacted the GitLab instance |

You can also edit, pause, or remove each runner.

### Administering Gitaly servers

You can list all Gitaly servers in the GitLab instance from the Admin Area's **Gitaly Servers**
page. For more details, see [Gitaly](../../administration/gitaly/index.md).

To access the **Gitaly Servers** page:

1. On the top bar, select **Menu >** **{admin}** **Admin**.
1. In the left sidebar, select **Overview > Gitaly Servers**.

For each Gitaly server, the following details are listed:

| Field          | Description |
|----------------|-------------|
| Storage        | Repository storage |
| Address        | Network address on which the Gitaly server is listening |
| Server version | Gitaly version |
| Git version    | Version of Git installed on the Gitaly server |
| Up to date     | Indicates if the Gitaly server version is the latest version available. A green dot indicates the server is up to date. |

## Monitoring section

The following topics document the **Monitoring** section of the Admin Area.

### System Information

The **System Info** page provides the following statistics:

| Field        | Description |
|:-------------|:------------|
| CPU          | Number of CPU cores available |
| Memory Usage | Memory in use, and total memory available |
| Disk Usage   | Disk space in use, and total disk space available |
| Uptime       | Approximate uptime of the GitLab instance |

These statistics are updated only when you navigate to the **System Info** page, or you refresh the page in your browser.

### Background Jobs

The **Background Jobs** page displays the Sidekiq dashboard. Sidekiq is used by GitLab to
perform processing in the background.

The Sidekiq dashboard consists of the following elements:

- A tab per jobs' status.
- A breakdown of background job statistics.
- A live graph of **Processed** and **Failed** jobs, with a selectable polling interval.
- An historical graph of **Processed** and **Failed** jobs, with a selectable time span.
- Redis statistics, including:
  - Version number
  - Uptime, measured in days
  - Number of connections
  - Current memory usage, measured in MB
  - Peak memory usage, measured in MB

### Logs

Since GitLab 13.0, **Log** view has been removed from the admin dashboard since the logging does not work in multi-node setups and could cause confusion for administrators by displaying partial information.

For multi-node systems we recommend ingesting the logs into services like Elasticsearch and Splunk.

| Log file                | Contents |
|:------------------------|:---------|
| `application.log`       | GitLab user activity |
| `git_json.log`          | Failed GitLab interaction with Git repositories |
| `production.log`        | Requests received from Puma, and the actions taken to serve those requests |
| `sidekiq.log`           | Background jobs |
| `repocheck.log`         | Repository activity |
| `integrations_json.log` | Activity between GitLab and integrated systems |
| `kubernetes.log`        | Kubernetes activity |

The contents of these log files can be useful when troubleshooting a problem.

For details of these log files and their contents, see [Log system](../../administration/logs.md).

The content of each log file is listed in chronological order. To minimize performance issues, a maximum 2000 lines of each log file are shown.

### Requests Profiles

The **Requests Profiles** page contains the token required for profiling. For more details, see [Request Profiling](../../administration/monitoring/performance/request_profiling.md).

### Audit Events **(PREMIUM SELF)**

The **Audit Events** page lists changes made within the GitLab server. With this information you can control, analyze, and track every change.
